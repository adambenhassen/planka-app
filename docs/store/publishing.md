# Publishing to Google Play and the App Store

Listing text lives in `fastlane/metadata/` (`android/en-US/` is the Play +
F-Droid tree, `en-US/` is the App Store `deliver` tree). Compliance answers are
in `compliance-answers.md`; the privacy policy is `privacy-policy.md`.

## Build flavors

Android has two flavors, same `applicationId` (`app.planka.planka_app`):

| Flavor   | Goes to             | In-app updater | `REQUEST_INSTALL_PACKAGES` |
|----------|---------------------|----------------|----------------------------|
| `github` | GitHub release APK  | yes            | yes                        |
| `store`  | Play, later F-Droid | no             | no                         |

Both stores forbid an app that installs its own updates, so the store flavor
drops the permission (`android/app/src/store/AndroidManifest.xml`) and compiles
the Dart path out via `--dart-define=ENABLE_IN_APP_UPDATER=false`.

Because flavors exist, local builds and `flutter run` need one:

```bash
flutter run --flavor github
flutter build appbundle --release --flavor store --dart-define=ENABLE_IN_APP_UPDATER=false
```

iOS has no flavors — the updater is Android-only.

## What CI produces

Tagging `v*` runs `.github/workflows/release.yml`:

- `planka-android.apk` — attached to the GitHub release (`github` flavor).
- `planka-play-appbundle` — **workflow artifact**, the `.aab` for the Play
  Console. Kept off the public release page.
- `planka-ios-unsigned-xcarchive` — **workflow artifact**, an unsigned
  `.xcarchive`. It proves the iOS build is green; it cannot be exported to an
  `.ipa` or uploaded until signing certificates exist.

## Screenshots

Not committed yet — the ones in `.github/assets/screenshots/` are 1206x2436
(iPhone 16 Pro) and are the wrong size for the App Store.

- **Play:** 2–8 phone screenshots, 16:9 or 9:16, each side 320–3840 px. Capture
  on an Android emulator. Drop them in
  `fastlane/metadata/android/en-US/images/phoneScreenshots/`.
- **App Store:** 6.9" (1320x2868 or 1290x2796) is mandatory; iPad 13" is
  required only if the iPad build is offered. Capture on an iPhone 16 Pro Max
  simulator and put them in `fastlane/screenshots/en-US/`.

Both come from the existing driver — change the `-d` device:

```bash
./dev/seed_demo.sh
flutter drive --driver=test_driver/screenshots_driver.dart \
  --target=integration_test/screenshots_test.dart -d "iPhone 16 Pro Max"
```

## Google Play, first release

1. Developer account, $25 one-time.
2. Enrol in Play App Signing. Choose **let Google generate the app signing
   key** and keep the existing `ANDROID_KEYSTORE_BASE64` keystore as the
   *upload* key. Do not upload the existing keystore as the app signing key:
   it also signs the sideloaded GitHub APK, and handing the same key to Play
   means a leak or loss affects both channels at once.
3. Store listing from `fastlane/metadata/android/en-US/`, privacy policy URL,
   data safety form, content rating, target audience.
4. Upload the `.aab` to a closed track.
5. **New personal developer accounts must run a closed test with at least 12
   testers opted in for 14 continuous days before production access is
   granted.** Organisation accounts are exempt. Line the testers up before
   starting the clock.
6. Production rollout, staged.

## App Store, first release

1. Apple Developer Program, $99/year.
2. In App Store Connect: create the app record with bundle id
   `app.planka.plankaApp`, then create the distribution certificate and
   provisioning profile (or let Xcode manage signing).
3. Build and upload a signed archive. Once the certificates exist, the CI job
   can be switched from `--no-codesign` to a signed `flutter build ipa` with
   an `ExportOptions.plist`; until then upload from a Mac with Xcode.
4. TestFlight, then submit for review with the review notes and the demo
   account from `compliance-answers.md`. Review needs a reachable demo Planka
   server — a throwaway instance that stays up for the whole review.

## Version bumps

`pubspec.yaml` `version: x.y.z+N` drives both stores. Play rejects a reused
`versionCode`, App Store Connect rejects a reused `CFBundleVersion` for the
same `CFBundleShortVersionString`, so `+N` must increase on every upload.
