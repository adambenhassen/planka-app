<p align="center">
  <img src=".github/assets/banner.svg" alt="Planka App — a Flutter mobile client for self-hosted Planka boards" width="100%">
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white"></a>
  <a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white"></a>
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows-3DDC84">
  <img alt="Planka" src="https://img.shields.io/badge/Planka-2.x-4675A4">
</p>

<p align="center">
  A Flutter client for <a href="https://github.com/plankanban/planka">Planka</a>, the open-source kanban board — on mobile and desktop.<br>
  Connect to your self-hosted server and manage boards on the go — with realtime sync.
</p>

---

## Screenshots

<p align="center">
  <img src=".github/assets/screenshots/projects.png" alt="Projects screen" width="45%">
  <img src=".github/assets/screenshots/board.png" alt="Kanban board" width="45%">
</p>
<p align="center">
  <img src=".github/assets/screenshots/card.png" alt="Card details" width="45%">
  <img src=".github/assets/screenshots/notifications.png" alt="Notifications" width="45%">
</p>

## Features

- 🔐 **Multi-account** — log in to multiple Planka servers, switch instantly
- 🗂 **Projects & boards** — browse everything you have access to, set project backgrounds, manage project managers
- 🎯 **Kanban board** — drag-and-drop cards across lists, live-synced over WebSocket; filter and sort cards
- 🃏 **Full card details** — description, due dates, labels, members, checklists, attachments, comments, activity feed
- ✏️ **Complete CRUD** — create, rename, edit, and delete cards, lists, labels, checklists, tasks, and comments from the app
- 📦 **Move, duplicate & restore** — move cards across boards and projects, duplicate cards, browse archive/trash and restore
- 👤 **Profile & admin** — edit your profile and avatar; admins can manage server users
- 🔔 **Notifications** — realtime unread badge, mark read / mark all read
- ⚡ **Realtime everywhere** — changes from the web UI appear instantly, and vice versa
- 🔄 **In-app updates** — sideloaded Android builds download and install new releases directly

> **Status:** actively maintained. Feature parity with the Planka web UI is largely complete across cards, boards, projects, and admin.

## Requirements

- A self-hosted **Planka 2.x** server
- Flutter **≥ 3.22** (stable) to build from source

## Getting Started

```bash
git clone https://github.com/adambenhassen/planka-app.git
cd planka-app
flutter pub get
flutter run
```

Sign in with your server URL (e.g. `https://planka.example.com`), email or username, and password.

## Development

A disposable Planka server for development and fixture recording:

```bash
docker compose -f dev/docker-compose.yml up -d   # Planka at http://localhost:3000
./dev/record_fixtures.sh                          # records API fixtures into test/fixtures/
```

Default dev credentials: `demo@demo.demo` / `demo`.

Regenerate the README screenshots (needs the dev server and an iOS simulator):

```bash
./dev/seed_demo.sh
flutter drive --driver=test_driver/screenshots_driver.dart --target=integration_test/screenshots_test.dart -d "iPhone 16 Pro"
```

Verify before committing:

```bash
dart analyze && flutter test
```

## Architecture

```mermaid
graph LR
    UI[Material 3 UI] --> State[Riverpod state]
    State --> REST[dio REST client]
    State --> WS[Socket.io client<br/>sails.io protocol]
    REST --> Server[(Planka 2.x server)]
    WS --> Server
```

- **API layer** — `dio` REST client + Socket.io client speaking the sails.io.js virtual-request protocol; freezed models parsed from Planka's `{item, included}` envelope
- **State layer** — Riverpod; one in-memory board state per open board, patched by both REST responses and socket events
- **UI layer** — Material 3: login → projects → board → card sheet → notifications

## Translations

UI strings live in ARB files under `lib/l10n/`, generated into `lib/l10n/gen/` by
Flutter's `gen-l10n` (configured in `l10n.yaml`). English (`app_en.arb`) is the
template every other locale is translated from. The app follows the system
locale and falls back to English for anything it doesn't ship.

To add one — German, say:

```bash
cp lib/l10n/app_en.arb lib/l10n/app_de.arb   # then translate the values
flutter pub get                               # regenerates lib/l10n/gen/
```

In the copy, set `"@@locale": "de"` and translate only the values. Leave the
keys and the `{placeholder}` names untouched — they are what the code calls.
The `@key` metadata blocks describe where each string appears; drop them from
the translated file. A locale may be partial: missing keys fall back to
English. Commit the regenerated `lib/l10n/gen/` along with the ARB file.

## Contributing

Issues and pull requests are welcome. Please run `dart analyze && flutter test` before submitting.

## Related Projects

- [planka-mcp](https://github.com/adambenhassen/planka-mcp) — an MCP server for Planka, letting AI assistants manage your boards
- [Planka](https://github.com/plankanban/planka) — the kanban board this app is a client for
