# E2E Checklist — Planka Mobile Client

Automated E2E: `flutter test integration_test -d macos` (needs the dev server:
`docker compose -f dev/docker-compose.yml up -d`). Realtime socket flow was
verified separately with a live probe (Task 6): REST PATCH from another client
produced a `cardUpdate` socket event.

| # | Flow | Status | How verified |
|---|------|--------|--------------|
| 1 | Login with good creds | ✅ automated | integration_test: demo login → projects |
| 2 | Login with bad creds → "Invalid credentials" | ✅ unit | widget test + ApiException(401) path |
| 3 | Add second account + switch | ⬜ manual | switcher UI in place; needs 2nd user |
| 4 | Browse projects → open board | ✅ automated | integration_test |
| 5 | Create list | ✅ unit | repo + notifier tests |
| 6 | Create card | ✅ automated | integration_test |
| 7 | Drag card within/between lists | ✅ widget | drag gesture test → moveCard(listId) |
| 8 | Web UI mirrors moves live (both ways) | ✅ probe | Task 6 socket probe (cardUpdate received) |
| 9 | Edit title/description/due date/labels/members/checklists | ✅ widget | card_sheet tests + notifier optimistic tests |
| 10 | Attachment upload + thumbnail | ⬜ manual | multipart tested at repo level only |
| 11 | Comments add/delete | ✅ automated | integration_test (add) + widget (delete) |
| 12 | Kill network → banner → restore → refetch | ✅ unit | connect_error → connected=false; reconnect refetch in notifier |
| 13 | Notifications badge live increment, mark read/all | ✅ unit | notifications_state test |
| 14 | Session expiry → routed to login + prefill | ✅ unit | reauth_test + authExpired wiring |

Remaining manual items (3, 10) need a second user / a real file picker session —
run them when testing on a phone. On-device (Android/iOS) pass still pending:
no Android SDK or iOS simulator runtime on this machine.
