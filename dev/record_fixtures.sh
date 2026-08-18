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

# A second project, recorded last so the fixtures above stay custom-field free.
# Covers every shape a card can carry: a board group, a card-only group, and a
# board group instantiated from a project-level base group — whose name and
# fields the board response omits, so they come from the project response.
CFP=$(curl -s -X POST $BASE/projects -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Custom Field Project","type":"private"}' | jq -r .item.id)
CFB=$(curl -s -X POST $BASE/projects/$CFP/boards -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Custom Field Board","position":16384}' | jq -r .item.id)
CFL=$(curl -s -X POST $BASE/boards/$CFB/lists -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"To Do","type":"active","position":16384}' | jq -r .item.id)
CFC=$(curl -s -X POST $BASE/lists/$CFL/cards -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Custom field card","type":"project","position":16384}' | jq -r .item.id)
# Second in position order, to prove groups render in the server's order.
BG=$(curl -s -X POST $BASE/boards/$CFB/custom-field-groups -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"BG","position":32768}' | jq -r .item.id)
F=$(curl -s -X POST $BASE/custom-field-groups/$BG/custom-fields -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"F","position":16384,"showOnFrontOfCard":false}' | jq -r .item.id)
FRONT=$(curl -s -X POST $BASE/custom-field-groups/$BG/custom-fields -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Front","position":32768,"showOnFrontOfCard":true}' | jq -r .item.id)
# No value is ever set for this one — it must still render, name and all.
curl -s -X POST $BASE/custom-field-groups/$BG/custom-fields -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Empty","position":49152,"showOnFrontOfCard":true}' > /dev/null
curl -s -X PATCH "$BASE/cards/$CFC/custom-field-values/customFieldGroupId:$BG:customFieldId:$F" -H "$AUTH" -H 'Content-Type: application/json' -d '{"content":"hello"}' > /dev/null
curl -s -X PATCH "$BASE/cards/$CFC/custom-field-values/customFieldGroupId:$BG:customFieldId:$FRONT" -H "$AUTH" -H 'Content-Type: application/json' -d '{"content":"on front"}' > /dev/null
CG=$(curl -s -X POST $BASE/cards/$CFC/custom-field-groups -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"CG","position":16384}' | jq -r .item.id)
CF=$(curl -s -X POST $BASE/custom-field-groups/$CG/custom-fields -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"CF","position":16384,"showOnFrontOfCard":false}' | jq -r .item.id)
curl -s -X PATCH "$BASE/cards/$CFC/custom-field-values/customFieldGroupId:$CG:customFieldId:$CF" -H "$AUTH" -H 'Content-Type: application/json' -d '{"content":"card level"}' > /dev/null
BCG=$(curl -s -X POST $BASE/projects/$CFP/base-custom-field-groups -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"Base"}' | jq -r .item.id)
BF=$(curl -s -X POST $BASE/base-custom-field-groups/$BCG/custom-fields -H "$AUTH" -H 'Content-Type: application/json' -d '{"name":"BF","position":16384,"showOnFrontOfCard":false}' | jq -r .item.id)
BASED=$(curl -s -X POST $BASE/boards/$CFB/custom-field-groups -H "$AUTH" -H 'Content-Type: application/json' -d "{\"baseCustomFieldGroupId\":\"$BCG\",\"position\":16384}" | jq -r .item.id)
curl -s -X PATCH "$BASE/cards/$CFC/custom-field-values/customFieldGroupId:$BASED:customFieldId:$BF" -H "$AUTH" -H 'Content-Type: application/json' -d '{"content":"based"}' > /dev/null

curl -s $BASE/boards/$CFB -H "$AUTH" > $OUT/board_show_custom_fields.json
curl -s $BASE/projects/$CFP -H "$AUTH" > $OUT/project_show_custom_fields.json
echo "fixtures written to $OUT"
