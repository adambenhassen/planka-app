# Store compliance answers

The questionnaires both consoles ask, answered once here so every submission
gives the same answers. Source of truth for the claims below:
`lib/` has no analytics, ads or crash-reporting dependency (see `pubspec.yaml`),
and the only network destinations are the server URL the user types and — in
the sideloaded Android build only — `api.github.com` for the update check
(`lib/update/update_service.dart`).

## Google Play — Data safety form

- **Does your app collect or share any of the required user data types?** No.
- **Is all of the user data collected by your app encrypted in transit?** Yes
  (when the user's server is HTTPS; the app supports plain HTTP because a
  self-hosted server on a LAN may not have a certificate).
- **Do you provide a way for users to request that their data is deleted?** Not
  applicable — no data reaches the developer. Account data lives on the user's
  own server and is deleted there.

The judgement call: the app does transmit credentials and board content off the
device, but only to an endpoint the user names and controls, and never to the
developer or a third party. Play's data-safety scope is data the developer or
its partners collect, so the answer is "no collection". If a reviewer pushes
back, the fallback is to declare "Personal info → Email address" and "App
activity" as *collected, not shared, required for app functionality, encrypted
in transit* and explain the self-hosted model in the review notes — this is the
same shape other self-hosted clients (Nextcloud, Home Assistant) declare.

- **Ads:** none. **Content rating questionnaire:** no objectionable content;
  expect Everyone / PEGI 3. **Target audience:** 18+, not directed at children.
- **Government/financial/health app:** no. **COVID/news app:** no.

## Apple — App privacy ("nutrition labels")

- **Data collection:** "Data Not Collected" for every category.
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
