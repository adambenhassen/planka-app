#!/usr/bin/env bash
set -euo pipefail
BASE=http://localhost:3000/api
OUT=test/fixtures; mkdir -p $OUT

TOKEN=$(curl -s -X POST $BASE/access-tokens -H 'Content-Type: application/json' \
  -d '{"emailOrUsername":"demo@demo.demo","password":"demo"}' | tee $OUT/login.json | jq -r .item)

# First-ever login returns {step:"accept-terms", pendingToken}: accept, then re-login.
if [ "$TOKEN" = "null" ]; then
  PT=$(jq -r .pendingToken $OUT/login.json)
  SIG=$(curl -s $BASE/terms -H "Authorization: Bearer $PT" | jq -r .item.signature)
  curl -s -X POST $BASE/access-tokens/accept-terms -H 'Content-Type: application/json' \
    -d "{\"pendingToken\":\"$PT\",\"signature\":\"$SIG\"}" > /dev/null
  TOKEN=$(curl -s -X POST $BASE/access-tokens -H 'Content-Type: application/json' \
    -d '{"emailOrUsername":"demo@demo.demo","password":"demo"}' | tee $OUT/login.json | jq -r .item)
fi
AUTH="Authorization: Bearer $TOKEN"

PROJECT=$(curl -s -X POST $BASE/projects -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Fixture Project","type":"private"}' | jq -r .item.id)
BOARD=$(curl -s -X POST $BASE/projects/$PROJECT/boards -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Fixture Board","position":16384}' | jq -r .item.id)
LIST=$(curl -s -X POST $BASE/boards/$BOARD/lists -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"To Do","type":"active","position":16384}' | jq -r .item.id)
CARD=$(curl -s -X POST $BASE/lists/$LIST/cards -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Fixture card","type":"project","position":16384}' | tee $OUT/card.json | jq -r .item.id)
curl -s -X POST $BASE/cards/$CARD/comments -H "$AUTH" -H 'Content-Type: application/json' -d '{"text":"hello"}' > $OUT/comment.json
TL=$(curl -s -X POST $BASE/cards/$CARD/task-lists -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Checklist","position":16384}' | jq -r .item.id)
curl -s -X POST $BASE/task-lists/$TL/tasks -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"task 1","position":16384}' > /dev/null
curl -s -X POST $BASE/boards/$BOARD/labels -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"bug","color":"berry-red","position":16384}' > /dev/null

curl -s $BASE/projects -H "$AUTH" > $OUT/projects_index.json
curl -s $BASE/boards/$BOARD -H "$AUTH" > $OUT/board_show.json
curl -s $BASE/notifications -H "$AUTH" > $OUT/notifications_index.json
echo "fixtures written to $OUT"
