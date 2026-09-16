# Privacy Policy

_Last updated: 16 September 2026_

Planka - Kanban Client ("the app") is an open-source client for
[Planka](https://github.com/plankanban/planka), a kanban board you host
yourself. This policy covers the app only.

## What the developer receives

Nothing. The app has no analytics, no crash reporting, no advertising, no
tracking identifiers, and no backend operated by the developer. No data about
you or your device is ever sent to the developer.

## Where your data goes

The app connects to one place for Planka data: the origin of the server address
you enter when you sign in. Your email or username, your password, and
everything you read or write in the app travel between your device and that
server and nowhere else. Media URLs returned by the server are used only when
their scheme, host, and port match that configured origin; a foreign media URL
is not loaded with your session credentials. That server is operated by you or
by whoever you chose to host it — how it handles your data is governed by that
operator, not by this app.

Whether that traffic is encrypted is determined by the address you enter. An
`https://` address is encrypted in transit by the operating system. The app
also accepts `http://`, because a self-hosted server on a local network often
has no certificate, and over `http://` your credentials and board content are
sent unencrypted. Use `https://` wherever your server supports it.

The one exception is the sideloaded Android build downloaded from GitHub, which
asks GitHub's public releases API whether a newer version exists. If an update
is available, it downloads the APK from the GitHub-provided release-asset URL
and follows that download's redirects. None of these updater requests carries
account data. Builds installed from Google Play or F-Droid, and iOS builds, do
not make them.

## What is stored on your device

- A secure account record for each account you add, containing the Planka server
  URL, access token, user ID, and display name. On iOS and Android it is held in
  the operating system's encrypted credential store (Keychain on iOS,
  Keystore-backed storage on Android).
- A plain-JSON content cache with no expiry. Successful project and board
  responses are stored on the device, including project, board, card, task and
  custom-field content and returned user records. The cache keys include the
  account id, but it is not encrypted.
- A cache of images already downloaded from your server — avatars, card covers,
  board backgrounds and attachments — so they do not have to be fetched again.

All of it stays on the device. In this version there is no reachable user-facing
sign-out or account-removal action: `AccountsNotifier.remove` and
`PlankaApi.logout` exist in the code but no UI calls them, and switching
accounts does not purge either cache. The plain-JSON cache therefore remains
until its entries are overwritten or individually removed, or the app is
uninstalled. The image cache is likewise removed when the app is uninstalled.

## Account creation and deletion

An administrator can create Planka user accounts from the app's user-management
screen. The app does not create an account on a developer-operated service. This
version provides no user-facing self-deletion or local account-removal path, so
requests to delete a Planka account must be handled by the server operator.

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
