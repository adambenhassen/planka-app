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
  - *Personal info → Email address* — **required**. Sent to `POST
    /access-tokens` at sign-in, and nothing in the app works before that.
  - *Personal info → User IDs* — **required**. Carried by every authenticated
    request once signed in.
  - *Personal info → Name* — **optional**. Not sent at sign-in; the login
    request is `emailOrUsername` and password only. A name leaves the device
    only when the user edits their profile (`PATCH /users/:id`) or an admin
    creates a user (`POST /users`).
  - *Photos and videos* — **optional**. Image attachments on a card, and the
    profile avatar (`POST /users/:id/avatar`).
  - *Files and docs* — **optional**. Non-image attachments on a card.
  - *Messages → Other in-app messages* — **optional**. Card comments.
  - *App activity → Other user-generated content* — **optional**. The free-form
    text the app sends that is neither a comment nor an attachment: card names
    and descriptions, list names, checklist and task text, project and board
    names, label names.
  - *App activity → Other actions* — **optional**. The edit actions themselves
    — moving, duplicating, archiving, assigning.
  Checked and deliberately **not** declared, because the app transmits none of
  them: location, contacts, calendar, device or other IDs, installed apps,
  audio, web browsing history, and app info and performance (there is no crash
  or diagnostics reporting). `package_info_plus` reads the local install source
  and never sends it.
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
