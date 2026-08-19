# Store compliance answers

The questionnaires both consoles ask, answered once here so every submission
gives the same answers. Source of truth for the claims below:
`lib/` has no analytics, ads or crash-reporting dependency (see `pubspec.yaml`),
and the only network destinations are the server URL the user types and — in
the sideloaded Android build only — `api.github.com` for the update check
(`lib/update/update_service.dart`).

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
  - *Personal info → User IDs* — **required**. The username half of the login
    body's `emailOrUsername` is a User ID under Play's taxonomy, and it is sent
    at sign-in. Also `PATCH /users/:id/username`, and the `userId` of other
    people when assigning project managers, board members and card members. Not
    the account id: that arrives from `GET /users/me`, is kept on the device,
    and leaves it only on the optional paths below — ordinary requests carry a
    bearer token, not an id.
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
    `color`.
  - *App activity → Other actions* — **optional**. The structural and status
    changes: `position`, `listId` and `boardId` moves, duplication, archive and
    trash, `isCompleted`, `isDueCompleted`, `isSubscribed`, `coverAttachmentId`,
    list `sort`, notification `isRead`, label and member assignment, and the
    admin `role` and `isDeactivated` changes — which are account permissions
    rather than personal information about the person.

  **Email address and User IDs are both required, and that is settled.** One
  sign-in field carries either, so exactly one of the two goes up at any given
  sign-in and the app cannot know which in advance. The test is not whether the
  user had a choice between two fields but whether anyone can use the app having
  supplied neither, and they cannot. Marking either *optional* would assert on
  the form that the user can decline it, which is false. *Required* overstates
  only which of the two a given user supplies, and the paragraph you are reading
  states that on the same page. An answer whose imprecision is written down
  beats one that is simply false; do not "correct" this to optional.

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
  code; and the `pendingToken` that carries a half-finished sign-in to that
  request and to `POST /access-tokens/accept-terms`.

  The `signature` in that accept-terms body declares nothing and is not user
  data: it is read out of the `GET /terms` response and echoed straight back.
  Noted for the same reason as the credentials — a field sitting unmentioned in
  a body the walk visited reads as an oversight, and nothing else tells a reader
  that it was considered.

  **How this list was produced, and how to redo it.** By walking every request
  body *and query parameter* the app can send, field by field, against Play's
  type list — not by adding types as they are noticed. Bodies alone are not the
  whole surface: a walk defined over them would report a completeness it never
  checked, since a query parameter carries data off the device just as a body
  does. Today `beforeId` on `GET /cards/:id/actions` is the only one, and it is
  an opaque server id, so it declares nothing. The board's search text is the
  case to watch: `BoardFilter.query` filters cards already on the device and
  never reaches the API layer, so *App activity → Search history* is correctly
  absent — and would stop being absent the day search moves server-side.

  The surface to walk is every `api.post`, `api.patch` and `api.delete` in
  `lib/api/repositories.dart`, every `api.get` there that passes `query:`, and
  `login`, `acceptTerms` and `verifyTotp` in `lib/api/planka_api.dart`. The
  untyped `patch` and `body` maps are the part a reader cannot check from the
  repository layer alone: their fields are set in `lib/state/board_state.dart`
  (card, list, label, task and board patches),
  `lib/state/projects_state.dart` (project patches),
  `lib/ui/widgets/profile_dialog.dart` (`name`, `phone`, `organization`,
  `avatar`) and `lib/ui/widgets/user_management_dialog.dart` (`role`,
  `isDeactivated`, and the `POST /users` body). Custom fields are read-only and
  send nothing. Re-walk those files when the API surface changes; do not patch
  this list one type at a time.

  This file shares no file with the code it describes, so it can go stale
  without anything conflicting, failing or otherwise saying so — the two-factor
  sign-in flow landed after the first walk and made the credentials note wrong
  while every check stayed green. A change to the API layer or the auth flow is
  the trigger to re-walk; nothing will remind you.
- **Is all of the user data collected by your app encrypted in transit?** No.
  Explanation for the form: the app connects only to a server address the user
  supplies, and a self-hosted Planka on a local network commonly has no TLS
  certificate, so plain HTTP has to keep working. HTTPS is used whenever the
  user's server offers it, and the address field defaults to `https://`.
- **Do you provide a way for users to request that their data is deleted?** The
  app creates no account on any developer-operated service and holds no
  server-side data to delete. Data lives on the user's own Planka server and is
  deleted there; signing out removes the account and its stored credentials
  from the device.

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
  app does not create accounts on a developer-operated service, so the
  in-app-deletion requirement does not apply. State this in the review notes.

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
