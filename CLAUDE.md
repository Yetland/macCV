# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
./build.sh              # Build debug + create .app bundle
./build.sh release      # Build release + create .app bundle
swift build             # Build only (no .app bundle)
swift build -c release  # Release build only
open build/MacCV.app    # Launch the app
```

## Architecture

macOS menu bar clipboard history app (SwiftUI + GRDB).

### Key modules

- **MacCVApp.swift** — App entry point, `MenuBarExtra` + `Settings` scene, `AppState` (Observable view model)
- **ClipboardMonitor.swift** — NSPasteboard polling (0.5s), posts `.clipboardDidUpdate` notification on new content
- **Storage/Database.swift** — GRDB SQLite store with FTS5 full-text search, image dedup via SHA256, singleton access
- **Models/HistoryItem.swift** — GRDB Codable model (id, type, content, imagePath, createdAt)
- **UI/** — SwiftUI views: HistoryPanel (host), HistoryListView (search + filter + list), HistoryItemRow, PreviewPanel, SettingsView
- **Utils/GlobalHotkey.swift** — Carbon RegisterEventHotKey for global shortcut
- **Utils/ImageCache.swift** — NSCache for image thumbnails

### Data flow

NSPasteboard changeCount polling → Database insert (dedup) → NotificationCenter `.clipboardDidUpdate` → AppState.refresh() → SwiftUI re-render

### Storage

- SQLite at `~/Library/Application Support/MacCV/db.sqlite`
- Images at `~/Library/Application Support/MacCV/Images/`
- FTS5 virtual table for text search

## Patterns

- Swift 6, `@Observable` for state management (no Combine)
- @unchecked Sendable for classes with internal locking (NSCache, DatabaseQueue)
- GRDB via singleton (Database.shared)
- NotificationCenter for cross-module events (clipboard updates)
