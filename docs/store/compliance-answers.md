# Store compliance answers

The questionnaires both consoles ask, answered once here so every submission
gives the same answers. Source of truth for the claims below:
`lib/` has no analytics, ads or crash-reporting dependency (see `pubspec.yaml`),
and the network destinations are the configured Planka server origin and — in
the sideloaded Android build only — GitHub's release API plus the release-asset
URL and redirect destination returned by that API (`lib/update/update_service.dart`).

## Google Play — Data safety form

**Declare collection.** Google defines collection as transmitting data off the
device, and there is no carve-out for an endpoint the user controls. That the
data reaches the user's own server and never the developer changes the
*sharing* answer, not the *collection* one.

- **Does your app collect or share any of the required user data types?**
  Collected, not shared. Every type is used only for **App functionality**, and
  none is processed ephemerally. *Required* means the app does not work without
  it; everything reached only by using a particular feature is *optional*,
  because a read-only user never transmits it.
  - *Personal info → Email address* — **required**. The email half of the login
    body's `emailOrUsername`, sent to `POST /access-tokens`. Nothing in the app
    works before sign-in. Also `PATCH /users/:id/email`, and an admin creating
    someone else's account with `POST /users`.
  - *Personal info → User IDs* — **optional**. The username half of the login
    body's `emailOrUsername` is a User ID under Play's taxonomy, but a user can
    sign in with an email address and does not have to provide a username. It is
    also sent by `PATCH /users/:id/username`, and the `userId` of other people
    is sent when assigning project managers, board members and card members.
    Not the account id: that arrives from `GET /users/me`, is kept on the
    device, and leaves it only on the optional paths below — ordinary requests
    carry a bearer token, not an id.
  - *Personal info → Name* — **optional**. `name` on `PATCH /users/:id` when the
    user edits their profile, and on `POST /users` when an admin creates
    someone. Not sent at sign-in.
  - *Personal info → Phone number* — **optional**. `phone` on
    `PATCH /users/:id`, from the profile editor.
  - *Personal info → Other info* — **optional**. `organization` on
    `PATCH /users/:id`, from the same editor.
  - *Photos and videos* — **optional**. Image attachments on a card, the
    profile avatar (`POST /users/:id/avatar`) and the project background
    (`POST /projects/:id/background-images`). Note, not reason: image
    attachments additionally get cover and thumbnail handling that other types
    do not.
  - *Audio files → Other audio files* — **optional**. An audio file sent through
    any of the three pickers. The app records nothing and uses no microphone.
  - *Files and docs* — **optional**. Everything else the user picks.

  The three file types above all follow from one fact: none of the three
  `openFile()` call sites — card attachment, avatar, project background — passes
  `acceptedTypeGroups`, so each of them can yield any file type at all. Each
  category Play names separately is therefore declared on its own, with *Files
  and docs* as the catch-all rather than as a substitute for a named category.

  - *Messages → Other in-app messages* — **optional**. Comment `text` on
    `POST /cards/:id/comments` and `PATCH /comments/:id`.
  - *App activity → Other user-generated content* — **optional**. The content
    fields of the board: card `name`, `description`, `dueDate` and `stopwatch`;
    list, task-list and task `name`; project and board `name`; label `name` and
    `color`; custom-field group and field `name`, and per-card custom-field
    value `content`.
  - *App activity → Other actions* — **optional**. The structural and status
    changes: `position`, `listId` and `boardId` moves, duplication, archive and
    trash, `isCompleted`, `isDueCompleted`, `isSubscribed`, `coverAttachmentId`,
    list `sort`, notification `isRead`, label and member assignment, and the
    admin `role` and `isDeactivated` changes — which are account permissions
    rather than personal information about the person. Custom-field `position`,
    `showOnFrontOfCard`, create/delete, and value-delete actions are included
    here too.

  **Email address is required; User IDs are optional.** The sign-in field accepts
  either value, and a user can proceed without a username. User IDs still need
  to be declared because the optional username, manager, assignee, membership,
  and user-management paths above can transmit them.

  Checked and deliberately **not** declared, because the app transmits none of
  them: location, contacts, calendar, device or other IDs, installed apps, web
  browsing history, health and fitness, financial info, and app info and
  performance (there is no crash or diagnostics reporting). `package_info_plus`
  reads the local install source and never sends it.

  Authentication credentials are transmitted and none of them is declarable:
  Play's taxonomy has no data type for them. That absence is deliberate, not an
  omission. What goes out is the password at sign-in, on a password change and
  when an admin creates a user; the two-factor `code` on
  `POST /access-tokens/verify-totp`, which is either a TOTP code or a recovery
  code; the `pendingToken` that carries a half-finished sign-in to that request
  and to `POST /access-tokens/accept-terms`; and the access token, which goes
  out on both channels — as the `Authorization: Bearer` header on REST requests
  and inside every socket frame, and as an `accessToken` cookie on image and
  attachment downloads.

  The `signature` in that accept-terms body declares nothing and is not user
  data: it is read out of the `GET /terms` response and echoed straight back.
  Noted for the same reason as the credentials — a field sitting unmentioned in
  a body the walk visited reads as an oversight, and nothing else tells a reader
  that it was considered.

  **How this list was produced, and how to redo it.** By walking every channel
  the app transmits on, field by field, against Play's type list — not by adding
  types as they are noticed. A completeness claim is only as wide as its stated
  scope, so the scope is written here: **two channels**, HTTP and the websocket.
  Both are listed below whether or not they contribute a type today, so that a
  reader can tell a channel that was considered from one that was never visited.

  *HTTP, to the server address the user entered.* Every `api.post`,
  `api.patch` and `api.delete` in `lib/api/repositories.dart`, every `api.get`
  there that passes `query:`, and `login`, `acceptTerms` and `verifyTotp` in
  `lib/api/planka_api.dart`. Two kinds of request do not go through the
  repository layer and are easy to miss: `PlankaApi.download`, and the
  `CachedNetworkImage` widgets in `card_tile.dart`, `board_background.dart` and
  `card_sections/attachments.dart`. The image widgets attach the access-token
  cookie only when `imageAuthHeaders` confirms the URL has the configured
  server's scheme, host and port; a foreign URL renders the no-image state.
  Redirects are disabled for these credentialed media requests. `PlankaApi.download`
  builds its URL from that same configured server. These requests send no other
  user data. The untyped `patch` and `body` maps are the part a reader cannot
  check from the repository layer alone: their fields are set in
  `lib/state/board_state.dart` (card, list, label, task and board patches),
  `lib/state/projects_state.dart` (project patches),
  `lib/ui/widgets/profile_dialog.dart` (`name`, `phone`, `organization`,
  `avatar`) and `lib/ui/widgets/user_management_dialog.dart` (`role`,
  `isDeactivated`, and the `POST /users` body). Custom-field group, field,
  position, display-flag, value, and deletion requests are sent through the
  methods in `lib/api/repositories.dart:105-165`; those paths justify the
  custom-field entries in the declared categories above.

  *Websocket, to the same server.* `lib/api/planka_socket.dart`. It contributes
  no data type today and is in the surface anyway, because it can: the handshake
  sends the three constant `__sails_io_sdk_*` parameters, and both empty-body
  emissions in the file — `subscribeBoard` to `/api/boards/:id?subscribe=true`
  and `subscribeUser` to `/api/users/me?subscribe=true` — carry the access token
  in the frame headers. `sailsRequestFrame` takes a `data` payload, so the day
  anything is emitted through it with a body, this channel starts carrying user
  data and must be re-walked.

  Query parameters count as much as bodies, on either channel — they carry data
  off the device the same way. On HTTP, `beforeId` on `GET /cards/:id/actions`
  is the only query parameter that carries anything user-supplied, and it is an
  opaque server id, so it declares nothing; the socket's are constants and a
  board id. The board's search text is the case to watch: `BoardFilter.query`
  filters cards already on the device and never reaches either channel, so
  *App activity → Search history* is correctly absent — and would stop being
  absent the day search moves server-side.

  The updater adds GitHub destinations without adding a third data channel: the
  sideloaded Android build checks `api.github.com` over HTTP and, when a newer
  APK exists, `downloadUpdate` downloads the `browser_download_url` returned by
  that response and follows its release-asset host or redirects. Neither
  request sends user data (see `lib/update/update_service.dart:23-68`).

  Re-walk both channels when the API surface changes; do not patch this list one
  type at a time.

  This file shares no file with the code it describes, so it can go stale
  without anything conflicting, failing or otherwise saying so — the two-factor
  sign-in flow landed after the first walk and made the credentials note wrong
  while every check stayed green. A change to either channel or to the auth flow
  is the trigger to re-walk; nothing will remind you.
- **Is all of the user data collected by your app encrypted in transit?** No.
  Explanation for the form: the app connects only to a server address the user
  supplies, and a self-hosted Planka on a local network commonly has no TLS
  certificate, so plain HTTP has to keep working. HTTPS is used whenever the
  user's server offers it, and the address field defaults to `https://`.
- **Do you provide a way for users to request that their data is deleted?**
  **No.** The app supports in-app Planka account creation: an administrator can
  create a user through `lib/ui/widgets/user_management_dialog.dart:86-90,104-171`,
  which calls `POST /users` through `lib/api/repositories.dart:225-227`. This
  build has no user-facing self-deletion or local sign-out/account-removal path:
  the signed-in user is excluded from the delete menu at
  `lib/ui/widgets/user_management_dialog.dart:209-232`, and no reachable UI calls
  `AccountsNotifier.remove` or `PlankaApi.logout` (`lib/auth/auth_providers.dart:42-50`,
  `lib/api/planka_api.dart:243-246`). No deletion-request URL is declared. A
  server operator controls deletion of the Planka data on that server.

Do not soften the two answers above into "No collection" or "encrypted in
transit: Yes" because the developer receives nothing — that reasoning was
tried and is wrong. Nextcloud, the closest precedent, declares
collected-not-shared on its own Play listing. Apple's answer is "Data Not
Collected" and that is deliberate, not a contradiction to reconcile: see the
App privacy section below for why the two tests differ.

- **Ads:** none. **Content rating questionnaire:** no objectionable content;
  expect Everyone / PEGI 3. **Target audience:** 18+, not directed at children.
- **Government/financial/health app:** no. **COVID/news app:** no.

## Apple — App privacy ("nutrition labels")

- **Data collection: "Data Not Collected" for every category.** Decided, not a
  draft. Apple's test is data the developer or its partners access or store,
  which is a different question from Google's "transmitted off the device" —
  the two forms turn on different tests and disagreeing here is correct, not an
  inconsistency. There is no developer-operated service, no analytics or
  crash-reporting SDK, and on iOS the only network destination is the address
  the user types: the GitHub update check is Android-only and returns at the
  platform check in `updateCheckProvider` before any request is made
  (`lib/update/update_service.dart`). Nothing is accessible to the developer
  for any period, which is the whole of Apple's question. MAIN-478 confirms
  this answer; it does not decide it.
- **Do not "harmonise" this to match the Play declaration.** Making the two
  forms agree by treating one store's test as the other's is exactly the
  mistake this file already made once, in the other direction — see the note
  under the Data Safety form against re-deriving the "No" there. Both answers
  are right because the questions differ.
- **Third-party SDKs:** none that collect data. All dependencies
  (`dio`, `socket_io_client`, `flutter_secure_storage`, `go_router`,
  `cached_network_image`, `url_launcher`, `path_provider`, `open_filex`,
  `package_info_plus`, `file_selector`) are transport, storage or platform
  shims.
- **Tracking:** no. The app does not use IDFA and shows no ATT prompt.
- **Account deletion requirement (App Store Review Guideline 5.1.1(v)):** the
  app supports in-app creation of Planka user accounts through the admin user
  management flow, even though the server is self-hosted and not operated by
  the developer. The current build has no user-facing self-deletion or local
  sign-out/account-removal path, so answer **No** until that capability exists;
  do not state that the requirement is inapplicable.

## Export compliance

The app uses only the platform's standard HTTPS/TLS. That is exempt, and
`ITSAppUsesNonExemptEncryption=false` is set in `ios/Runner/Info.plist`, so App
Store Connect stops asking per build. On Play, answer the US export-law
declaration as "does not use encryption beyond what is exempt".

## Third-party client disclaimer

The listing title leads with a name the developer does not own. App Store
Review Guideline 4.1 and Play's impersonation policy both routinely hold
third-party clients on exactly that, so both descriptions carry an explicit
"unofficial, not affiliated with the Planka project" line. It is the accepted
mitigation; the title does not have to change. Do not drop that paragraph when
editing listing copy.

## App Store review notes (paste into App Store Connect)

> This app is a client for Planka, an open-source kanban board that users host
> themselves. It has no backend of ours — it connects only to the server
> address the user enters at sign-in, so a server is required to see anything
> past the login screen. Demo server and credentials are in the demo account
> fields below. Source: https://github.com/adambenhassen/planka-app

## Privacy policy URL

<https://github.com/adambenhassen/planka-app/blob/main/docs/store/privacy-policy.md>

Both consoles accept a URL that renders publicly; the GitHub blob view does.
If a nicer URL is wanted, enable GitHub Pages for the repo and re-point
`fastlane/metadata/en-US/privacy_url.txt` and the Play Console field at it.
