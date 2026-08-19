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
  Collected, not shared. Every type below is *required* (not optional) and used
  only for **App functionality**; none is processed ephemerally:
  - *Personal info → Email address, User IDs, Name* — sign-in and the profile
    the server returns.
  - *Photos and videos*, *Files and docs* — attachments the user uploads to a
    card.
  - *Messages → Other in-app messages* — card comments.
  - *App activity → Other actions* — board, list and card edits.
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
collected-not-shared on its own Play listing.

- **Ads:** none. **Content rating questionnaire:** no objectionable content;
  expect Everyone / PEGI 3. **Target audience:** 18+, not directed at children.
- **Government/financial/health app:** no. **COVID/news app:** no.

## Apple — App privacy ("nutrition labels")

- **Data collection:** currently drafted as "Data Not Collected" for every
  category. **Unresolved — do not submit on this answer without MAIN-478.**
  Apple's definition turns on data the developer or its partners access or
  store, which is a different test from Google's "transmitted off the device",
  so the two forms can legitimately disagree. But this file already stated one
  Play answer confidently and wrongly, so the same reasoning does not get a
  second pass unreviewed.
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
