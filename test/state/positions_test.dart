import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/state/positions.dart';

// Tests for positionBetween, which is the arithmetic used by
// _moveCustomFieldGroup and _moveCustomField in board_state.dart.

void main() {
  group('positionBetween', () {
    test('no neighbours returns kPositionGap', () {
      expect(positionBetween(null, null), kPositionGap);
    });

    test('appending after last item adds kPositionGap', () {
      expect(positionBetween(32768, null), 32768 + kPositionGap);
    });

    test('prepending before first item halves it', () {
      expect(positionBetween(null, 16384), 8192.0);
    });

    test('inserting between two items is the midpoint', () {
      expect(positionBetween(16384, 32768), 24576.0);
    });

    // ── Simulates _moveCustomFieldGroup / _moveCustomField position math ──

    // Three groups at positions [a, b, c]; moving b up places it before a.
    // idx=1, up: before = null (idx-2 doesn't exist), after = peers[0] = a
    test('move item at index 1 up: midpoint of (null, a)', () {
      const a = 16384.0;
      expect(positionBetween(null, a), a / 2);
    });

    // Three groups [a, b, c]; moving c up places it between a and b.
    // idx=2, up: before = peers[0] = a, after = peers[1] = b
    test('move item at index 2 up: midpoint of (a, b)', () {
      const a = 16384.0;
      const b = 32768.0;
      expect(positionBetween(a, b), (a + b) / 2);
    });

    // Two groups [a, b]; moving a down places it after b.
    // idx=0, down: before = peers[1] = b, after = null (idx+2 >= length)
    test('move item at index 0 down with no successor: b + kPositionGap', () {
      const b = 32768.0;
      expect(positionBetween(b, null), b + kPositionGap);
    });

    // Three groups [a, b, c]; moving a down places it between b and c.
    // idx=0, down: before = peers[1] = b, after = peers[2] = c
    test('move item at index 0 down between b and c: midpoint', () {
      const b = 32768.0;
      const c = 49152.0;
      expect(positionBetween(b, c), (b + c) / 2);
    });

    // Idempotency: inserting repeatedly at the same gap stays within range
    test('repeated prepend converges without going negative', () {
      double pos = kPositionGap;
      for (var i = 0; i < 20; i++) {
        pos = positionBetween(null, pos);
      }
      expect(pos, greaterThan(0));
    });
  });
}
