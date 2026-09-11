#!/usr/bin/env bash
# Captures Store screenshots on one iOS simulator with bounded startup and
# driver execution. A stuck simulator must leave diagnostics for the workflow.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 DEVICE_ID OUTPUT_DIR" >&2
  exit 2
fi

DEVICE_ID=$1
OUTPUT_DIR=$2
BOOT_TIMEOUT_SECONDS=${STORE_IOS_BOOT_TIMEOUT_SECONDS:-180}
CAPTURE_TIMEOUT_SECONDS=${STORE_IOS_CAPTURE_TIMEOUT_SECONDS:-900}

: "${PLANKA_URL:?PLANKA_URL is required}"
: "${PLANKA_EMAIL:?PLANKA_EMAIL is required}"
: "${PLANKA_PASSWORD:?PLANKA_PASSWORD is required}"

mkdir -p "$OUTPUT_DIR"
BOOT_LOG="$OUTPUT_DIR/simctl-bootstatus.log"
CAPTURE_LOG="$OUTPUT_DIR/flutter-drive.log"
DIAGNOSTICS_LOG="$OUTPUT_DIR/diagnostics.log"

kill_tree() {
  local pid=$1
  local child

  for child in $(pgrep -P "$pid" 2>/dev/null || true); do
    kill_tree "$child"
  done
  kill -TERM "$pid" 2>/dev/null || true
}

write_diagnostics() {
  local reason=$1
  local command_log=$2

  {
    echo "=== Store iOS capture diagnostics ==="
    echo "reason=$reason"
    echo "device_id=$DEVICE_ID"
    echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "--- available simulator state ---"
    xcrun simctl list devices available 2>&1 || true
    echo "--- bootstatus output ---"
    tail -200 "$BOOT_LOG" 2>/dev/null || true
    echo "--- command output ---"
    tail -200 "$command_log" 2>/dev/null || true
    if grep -q 'VMServiceFlutterDriver: Connected to Flutter application.' "$command_log"; then
      echo "driver_connection=observed"
    else
      echo "driver_connection=not-observed"
    fi
    echo "--- relevant processes ---"
    ps -Ao pid,ppid,etime,command \
      | grep -E 'flutter|dart|xcodebuild|simctl|Runner' \
      | grep -v grep || true
  } | tee "$DIAGNOSTICS_LOG"
}

run_with_timeout() {
  local name=$1
  local timeout_seconds=$2
  local command_log=$3
  local command_pid
  local deadline
  local status

  shift 3
  : > "$command_log"
  echo "Starting $name (timeout ${timeout_seconds}s)"
  "$@" >"$command_log" 2>&1 &
  command_pid=$!
  deadline=$((SECONDS + timeout_seconds))

  while kill -0 "$command_pid" 2>/dev/null; do
    if (( SECONDS >= deadline )); then
      echo "$name exceeded ${timeout_seconds}s" >&2
      write_diagnostics "$name timed out" "$command_log"
      kill_tree "$command_pid"
      wait "$command_pid" 2>/dev/null || true
      return 124
    fi
    sleep 5
  done

  status=0
  if wait "$command_pid"; then
    status=0
  else
    status=$?
  fi
  cat "$command_log"
  if [ "$status" -ne 0 ]; then
    echo "$name failed with exit code $status" >&2
    write_diagnostics "$name failed" "$command_log"
    return "$status"
  fi
}

echo "Booting iOS simulator $DEVICE_ID"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
run_with_timeout \
  "simulator boot" \
  "$BOOT_TIMEOUT_SECONDS" \
  "$BOOT_LOG" \
  xcrun simctl bootstatus "$DEVICE_ID" -b

capture_attempt=1
while [ "$capture_attempt" -le 2 ]; do
  if [ "$capture_attempt" -gt 1 ]; then
    echo "Resetting iOS simulator before capture retry"
    # A launch that never publishes VM service can leave the simulator app
    # wedged. Reset only this ephemeral CI device before the single retry.
    xcrun simctl shutdown "$DEVICE_ID" 2>&1 || true
    xcrun simctl erase "$DEVICE_ID" 2>&1 || true
    xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
    BOOT_LOG="$OUTPUT_DIR/simctl-bootstatus-attempt-${capture_attempt}.log"
    run_with_timeout \
      "simulator boot retry" \
      "$BOOT_TIMEOUT_SECONDS" \
      "$BOOT_LOG" \
      xcrun simctl bootstatus "$DEVICE_ID" -b || exit $?
  fi

  CAPTURE_LOG="$OUTPUT_DIR/flutter-drive-attempt-${capture_attempt}.log"
  DIAGNOSTICS_LOG="$OUTPUT_DIR/diagnostics-attempt-${capture_attempt}.log"
  if run_with_timeout \
    "iOS screenshot capture attempt $capture_attempt" \
    "$CAPTURE_TIMEOUT_SECONDS" \
    "$CAPTURE_LOG" \
    env \
    "SCREENSHOT_OUTPUT_DIR=$OUTPUT_DIR" \
    STORE_SCREENSHOTS=1 \
    flutter drive \
    --driver=test_driver/screenshots_driver.dart \
    --target=integration_test/screenshots_test.dart \
    -d "$DEVICE_ID" \
    "--dart-define=PLANKA_URL=$PLANKA_URL" \
    "--dart-define=PLANKA_EMAIL=$PLANKA_EMAIL" \
    "--dart-define=PLANKA_PASSWORD=$PLANKA_PASSWORD"; then
    exit 0
  else
    status=$?
  fi

  if [ "$capture_attempt" -eq 2 ]; then
    exit "$status"
  fi
  echo "iOS screenshot capture attempt $capture_attempt failed; retrying once"
  capture_attempt=$((capture_attempt + 1))
done
