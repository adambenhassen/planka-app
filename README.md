<p align="center">
  <img src=".github/assets/banner.svg" alt="Planka App — a Flutter mobile client for self-hosted Planka boards" width="100%">
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white"></a>
  <a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white"></a>
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-Android%20%7C%20iOS-3DDC84">
  <img alt="Planka" src="https://img.shields.io/badge/Planka-2.x-4675A4">
</p>

<p align="center">
  A native mobile client for <a href="https://github.com/plankanban/planka">Planka</a>, the open-source kanban board.<br>
  Connect to your self-hosted server and manage boards on the go — with realtime sync.
</p>

---

## Features

- 🔐 **Multi-account** — log in to multiple Planka servers, switch instantly
- 🗂 **Projects & boards** — browse everything you have access to
- 🎯 **Kanban board** — drag-and-drop cards across lists, live-synced over WebSocket
- 🃏 **Full card details** — description, due dates, labels, members, checklists, attachments, comments
- 🔔 **Notifications** — realtime unread badge, mark read / mark all read
- ⚡ **Realtime everywhere** — changes from the web UI appear instantly, and vice versa

> **Status:** in active development. Core API layer, auth, and realtime socket client are done; UI screens are landing next.

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

## Contributing

Issues and pull requests are welcome. Please run `dart analyze && flutter test` before submitting.

## Related Projects

- [planka-mcp](https://github.com/adambenhassen/planka-mcp) — an MCP server for Planka, letting AI assistants manage your boards
- [Planka](https://github.com/plankanban/planka) — the kanban board this app is a client for
