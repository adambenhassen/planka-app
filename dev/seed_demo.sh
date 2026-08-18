#!/usr/bin/env bash
# Seeds the dev Planka (dev/docker-compose.yml) with demo data for README
# screenshots. Idempotent: skips if a "Product Launch" project already exists.
# Photos come from picsum.photos (fixed ids, so runs are reproducible).
set -euo pipefail
BASE=${PLANKA_URL:-http://localhost:3000}/api
J='Content-Type: application/json'
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

login() { # $1 email, $2 password → prints token
  local resp tok pt sig
  resp=$(curl -s -X POST $BASE/access-tokens -H "$J" -d "{\"emailOrUsername\":\"$1\",\"password\":\"$2\"}")
  tok=$(jq -r .item <<<"$resp")
  if [ "$tok" = "null" ]; then
    pt=$(jq -r .pendingToken <<<"$resp")
    sig=$(curl -s $BASE/terms -H "Authorization: Bearer $pt" | jq -r .item.signature)
    tok=$(curl -s -X POST $BASE/access-tokens/accept-terms -H "$J" \
      -d "{\"pendingToken\":\"$pt\",\"signature\":\"$sig\"}" | jq -r .item)
  fi
  echo "$tok"
}
post() { curl -s -X POST "$BASE$1" -H "$AUTH" -H "$J" -d "$2"; }
patch() { curl -s -X PATCH "$BASE$1" -H "$AUTH" -H "$J" -d "$2"; }
photo() { # picsum id, WxH → local path
  local f="$TMP/$1.jpg"
  [ -f "$f" ] || curl -sfL -o "$f" "https://picsum.photos/id/$1/${2/x//}"
  echo "$f"
}

TOKEN=$(login demo@demo.demo demo); AUTH="Authorization: Bearer $TOKEN"
DEMO_ID=$(curl -s $BASE/users/me -H "$AUTH" | jq -r .item.id)

if curl -s $BASE/projects -H "$AUTH" | jq -e '.items[]|select(.name=="Product Launch")' >/dev/null; then
  echo "already seeded"; exit 0
fi

# Second user (acts on cards → notifications for demo).
ALICE_ID=$(post /users '{"email":"alice@demo.demo","password":"Alice-demo-2026","name":"Alice Park","username":"alicedemo","role":"boardUser"}' | jq -r '.item.id // empty')
[ -z "$ALICE_ID" ] && ALICE_ID=$(curl -s $BASE/users -H "$AUTH" | jq -r '.items[]|select(.username=="alicedemo").id')

mkproject() { post /projects "{\"name\":\"$1\",\"type\":\"private\"}" | jq -r .item.id; }
gradient() { patch /projects/$1 "{\"backgroundType\":\"gradient\",\"backgroundGradient\":\"$2\"}" >/dev/null; }
photo_bg() { # project id, picsum id
  local img
  img=$(curl -s -X POST $BASE/projects/$1/background-images -H "$AUTH" -F "file=@$(photo $2 1200x1800)" | jq -r .item.id)
  patch /projects/$1 "{\"backgroundType\":\"image\",\"backgroundImageId\":\"$img\"}" >/dev/null
}
mkboard() { post /projects/$1/boards "{\"name\":\"$2\",\"position\":$3}" | jq -r .item.id; }

# Extra projects/boards so the projects screen has some life (created first so
# "Product Launch" sorts to the top as the newest).
P_WEB=$(mkproject "Website Redesign"); photo_bg $P_WEB 1015
mkboard $P_WEB "Content" 16384 >/dev/null; mkboard $P_WEB "Frontend" 32768 >/dev/null
P_OPS=$(mkproject "Ops & Infrastructure"); gradient $P_OPS "jungle-mesh"
mkboard $P_OPS "Incidents" 16384 >/dev/null; mkboard $P_OPS "On-call" 32768 >/dev/null

PROJECT=$(mkproject "Product Launch"); photo_bg $PROJECT 1018
BOARD=$(mkboard $PROJECT "Roadmap" 16384)
mkboard $PROJECT "Marketing" 32768 >/dev/null
post /boards/$BOARD/board-memberships "{\"userId\":\"$ALICE_ID\",\"role\":\"editor\"}" >/dev/null

mklist() { post /boards/$BOARD/lists "{\"name\":\"$1\",\"type\":\"active\",\"position\":$2}" | jq -r .item.id; }
BACKLOG=$(mklist Backlog 16384); PROGRESS=$(mklist "In Progress" 32768)
REVIEW=$(mklist Review 49152); DONE=$(mklist Done 65536)

mklabel() { post /boards/$BOARD/labels "{\"name\":\"$1\",\"color\":\"$2\",\"position\":$3}" | jq -r .item.id; }
L_DESIGN=$(mklabel Design lagoon-blue 16384); L_BUG=$(mklabel Bug berry-red 32768)
L_FEAT=$(mklabel Feature bright-moss 49152); L_DOCS=$(mklabel Docs pumpkin-orange 65536)

mkcard() { # list, name, position → id
  post /lists/$1/cards "{\"name\":\"$2\",\"type\":\"project\",\"position\":$3}" | jq -r .item.id
}
label() { post /cards/$1/card-labels "{\"labelId\":\"$2\"}" >/dev/null; }
member() { post /cards/$1/card-memberships "{\"userId\":\"$2\"}" >/dev/null; }
due() { patch /cards/$1 "{\"dueDate\":\"$2\"}" >/dev/null; }
describe() { patch /cards/$1 "$(jq -cn --arg d "$2" '{description:$d}')" >/dev/null; }
cover() { # card id, picsum id
  local att
  att=$(curl -s -X POST $BASE/cards/$1/attachments -H "$AUTH" -F type=file -F name="photo-$2.jpg" \
        -F "file=@$(photo $2 800x500)" | jq -r .item.id)
  patch /cards/$1 "{\"coverAttachmentId\":\"$att\"}" >/dev/null
}
tasks() { # card id, name, then "name:done" entries
  local tl pos=16384 t
  tl=$(post /cards/$1/task-lists "{\"name\":\"$2\",\"position\":16384}" | jq -r .item.id); shift 2
  for t in "$@"; do
    post /task-lists/$tl/tasks "{\"name\":\"${t%%:*}\",\"position\":$pos,\"isCompleted\":${t##*:}}" >/dev/null
    pos=$((pos + 16384))
  done
}
day() { date -u -v+"$1"d +%Y-%m-%dT"$2":00:00.000Z 2>/dev/null || date -u -d "+$1 days" +%Y-%m-%dT"$2":00:00.000Z; }

# Backlog
C1=$(mkcard $BACKLOG "Write launch blog post" 16384)
  label $C1 $L_DOCS; due $C1 "$(day 10 09)"; member $C1 $ALICE_ID
C2=$(mkcard $BACKLOG "Pricing page A/B test" 32768)
  label $C2 $L_FEAT; label $C2 $L_DESIGN; cover $C2 180
  describe $C2 "Test the two-tier vs three-tier layout on 10% of traffic."
C3=$(mkcard $BACKLOG "Localize app into 5 languages" 49152)
  member $C3 $DEMO_ID; tasks $C3 "Languages" "German:true" "French:false" "Spanish:false" "Japanese:false" "Portuguese:false"
C11=$(mkcard $BACKLOG "Migrate CI to self-hosted runners" 65536)
  label $C11 $L_BUG; due $C11 "$(day 14 12)"
C12=$(mkcard $BACKLOG "Launch-day social assets" 81920)
  label $C12 $L_DESIGN; cover $C12 20; member $C12 $ALICE_ID
C13=$(mkcard $BACKLOG "Customer interview notes" 98304)
  label $C13 $L_DOCS; describe $C13 "Summaries from the 8 beta interviews."
# In Progress
C4=$(mkcard $PROGRESS "Design onboarding flow" 16384)
  label $C4 $L_DESIGN; label $C4 $L_FEAT; member $C4 $DEMO_ID; member $C4 $ALICE_ID
  due $C4 "$(day 3 17)"; cover $C4 60
  describe $C4 $'Reduce drop-off in the first session.\n\n- Welcome screen with value prop\n- Server URL + login in one step\n- Empty-state hints on the board'
  tasks $C4 "Checklist" "Wireframes:true" "Hi-fi mockups:true" "Usability test (5 users):false" "Handoff to dev:false"
C5=$(mkcard $PROGRESS "Fix crash on rotate" 32768)
  label $C5 $L_BUG; member $C5 $DEMO_ID; due $C5 "$(day 1 10)"
C6=$(mkcard $PROGRESS "Push notification service" 49152)
  label $C6 $L_FEAT; member $C6 $DEMO_ID; tasks $C6 "Rollout" "APNs certs:true" "FCM project:true" "Server worker:false"
C14=$(mkcard $PROGRESS "App Store screenshots" 65536)
  label $C14 $L_DESIGN; cover $C14 160
# Review
C7=$(mkcard $REVIEW "Dark mode palette" 16384);              label $C7 $L_DESIGN; cover $C7 366
C8=$(mkcard $REVIEW "Offline queue for card edits" 32768);   label $C8 $L_FEAT; label $C8 $L_BUG; member $C8 $DEMO_ID
C15=$(mkcard $REVIEW "Release notes v1.10" 49152);           label $C15 $L_DOCS
# Done
C9=$(mkcard $DONE "Multi-account switcher" 16384);           label $C9 $L_FEAT
C10=$(mkcard $DONE "App icon" 32768);                        label $C10 $L_DESIGN; cover $C10 201
C16=$(mkcard $DONE "Realtime board sync" 49152);             label $C16 $L_FEAT

# Alice acts on cards demo is a member of → unread notifications for demo.
ATOKEN=$(login alice@demo.demo Alice-demo-2026); AUTH="Authorization: Bearer $ATOKEN"
post /cards/$C4/comments '{"text":"Mockups are up — take a look before Thursday?"}' >/dev/null
post /cards/$C5/comments '{"text":"Repro steps added, happens on iPad only."}' >/dev/null
post /cards/$C6/comments '{"text":"APNs cert is in the vault now."}' >/dev/null
post /cards/$C3/comments '{"text":"German strings are in review."}' >/dev/null
member $C7 $DEMO_ID
member $C1 $DEMO_ID
member $C12 $DEMO_ID
patch /cards/$C8 "{\"listId\":\"$DONE\",\"position\":65536}" >/dev/null
post /cards/$C4/comments '{"text":"Also: should the welcome screen mention self-hosting?"}' >/dev/null
echo "seeded project=$PROJECT board=$BOARD"
