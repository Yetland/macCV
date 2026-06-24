# MacCV

MacCV is a lightweight macOS menu bar clipboard history app built with SwiftUI and GRDB.

It watches the system clipboard, stores recent text and image entries locally, and lets you search or restore clipboard history from a compact menu bar panel.

## Features

- Menu bar clipboard history
- Text and image clipboard capture
- Full-text search with SQLite FTS5
- Image deduplication with SHA256
- Local-only storage under Application Support
- Global hotkey support
- SwiftUI settings window

## Requirements

- macOS 14 or later
- Swift 6 toolchain

## Build And Run

```bash
./build.sh              # Build debug and create build/MacCV.app
./build.sh release      # Build release and create build/MacCV.app
swift build             # Build only
swift build -c release  # Release build only
open build/MacCV.app    # Launch the app bundle
```

## Storage

MacCV stores data locally:

- Database: `~/Library/Application Support/MacCV/db.sqlite`
- Images: `~/Library/Application Support/MacCV/Images/`

## Project Layout

```text
Sources/MacCV/
  MacCVApp.swift                 App entry point and shared app state
  ClipboardMonitor.swift         NSPasteboard polling and clipboard events
  Models/HistoryItem.swift       Clipboard history model
  Storage/Database.swift         GRDB SQLite store and search
  UI/                            SwiftUI panels, rows, preview, settings
  Utils/                         Global hotkey and image cache helpers
Resources/
  AppIcon.svg                    Editable app icon source
  AppIcon.icns                   macOS app icon
  Info.plist                     App bundle metadata
```

## Development Notes

- Clipboard changes are detected by polling `NSPasteboard.changeCount`.
- Updates flow through `NotificationCenter` via `.clipboardDidUpdate`.
- `Database.shared` owns the GRDB queue and migrations.
- The generated `.app` bundle lives in `build/` and is ignored by git.
