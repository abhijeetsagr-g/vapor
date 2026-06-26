# Vapor

An open-source game launcher for Linux built with Flutter. Think Steam (both Desktop and Big Picture UI) without the store — a unified, polished game library manager.

**MVP scope:**
- Lutris import — reads `~/.local/share/lutris/pga.db`
- Manual add — name, executable, cover
- Metadata fetching from IGDB / SteamGridDB with offline cache
- Playtime tracking with optional Lutris sync
- Steam Library UI — desktop grid, detail panel, search, filters
- Steam Big Picture UI — fullscreen couch mode, controller navigation

## Tech Stack

- **Framework:** Flutter (Linux desktop target)
- **State management:** BLoC / Cubit
- **Database:** Drift (SQLite)
- **Architecture:** Feature-first clean architecture

## Getting Started

```bash
flutter pub get
flutter run -d linux
```

Requires Flutter's Linux desktop toolchain. See [Flutter Linux setup](https://docs.flutter.dev/platform-integration/linux/building).
