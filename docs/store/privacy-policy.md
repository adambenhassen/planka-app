# Privacy Policy

_Last updated: 18 August 2026_

Planka - Kanban Client ("the app") is an open-source client for
[Planka](https://github.com/plankanban/planka), a kanban board you host
yourself. This policy covers the app only.

## What the developer receives

Nothing. The app has no analytics, no crash reporting, no advertising, no
tracking identifiers, and no backend operated by the developer. No data about
you or your device is ever sent to the developer.

## Where your data goes

The app connects to one place: the Planka server address you enter when you
sign in. Your email or username, your password, and everything you read or
write in the app travel between your device and that server and nowhere else.
That server is operated by you or by whoever you chose to host it — how it
handles your data is governed by that operator, not by this app.

Whether that traffic is encrypted is determined by the address you enter. An
`https://` address is encrypted in transit by the operating system. The app
also accepts `http://`, because a self-hosted server on a local network often
has no certificate, and over `http://` your credentials and board content are
sent unencrypted. Use `https://` wherever your server supports it.

The one exception is the sideloaded Android build downloaded from GitHub, which
asks GitHub's public releases API whether a newer version exists. That request
carries no account data. Builds installed from Google Play or F-Droid do not
make it.

## What is stored on your device

- Server addresses, and the session credentials for each account you add, held
  in the operating system's encrypted credential store (Keychain on iOS,
  Keystore-backed storage on Android).
- A cache of images already downloaded from your server — avatars, card covers
  and attachments — so they do not have to be fetched again.

All of it stays on the device. Signing out removes that account and its stored
credentials; the image cache is cleared by uninstalling the app.

## Permissions

- **Internet** — required to reach your Planka server.
- **Install packages** (sideloaded Android build only) — lets the in-app
  updater hand a downloaded release to the system installer. The Google Play
  and F-Droid builds do not request it.

## Children

The app is not directed at children, and the developer receives no data from
anyone.

## Changes

Changes to this policy are published in this file; its history is public in the
repository.

## Contact

Questions and issues:
<https://github.com/adambenhassen/planka-app/issues>
