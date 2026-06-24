import SwiftUI

@main
struct MacCVApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("MacCV", systemImage: "clipboard") {
            HistoryPanel(viewModel: appState)
                .onReceive(NotificationCenter.default.publisher(for: .clipboardDidUpdate)) { _ in
                    appState.refresh()
                }
        }
        .menuBarExtraStyle(.window)
    }
}

@Observable
final class AppState {
    var items: [HistoryItem] = []
    var searchText = "" {
        didSet { refresh() }
    }
    var filterType: HistoryItem.ItemType? = nil {
        didSet { refresh() }
    }
    var selectedForPreview: HistoryItem? = nil
    var maxHistory: Int = 1000 {
        didSet {
            UserDefaults.standard.set(maxHistory, forKey: "maxHistory")
            refresh()
        }
    }

    private let monitor: ClipboardMonitor
    private let database = Database.shared

    init() {
        let saved = UserDefaults.standard.integer(forKey: "maxHistory")
        if saved > 0 {
            maxHistory = saved
        } else {
            UserDefaults.standard.set(1000, forKey: "maxHistory")
        }
        monitor = ClipboardMonitor(database: database)
        refresh()
        monitor.start()
    }

    func refresh() {
        let search = searchText.isEmpty ? nil : searchText
        items = database.fetchItems(search: search, filterType: filterType, limit: maxHistory)
    }

    func deleteItem(_ id: Int64) {
        database.deleteItem(id: id)
        refresh()
    }

    func clearAll() {
        database.deleteAll()
        ImageCache.shared.clear()
        items = []
    }

    @MainActor func showSettings() {
        NSApp.keyWindow?.close()
        let panel = SettingsPanel.shared
        panel.show(viewModel: self)
    }
}

// Singleton settings window (single instance)
@MainActor private final class SettingsPanel: NSObject {
    static let shared = SettingsPanel()
    private var window: NSWindow?

    @MainActor func show(viewModel: AppState) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: SettingsView(viewModel: viewModel).frame(width: 420, height: 320))
        let win = NSWindow(contentViewController: hosting)
        win.title = "MacCV Settings"
        win.styleMask = [.titled, .closable, .fullSizeContentView]
        win.isReleasedWhenClosed = false
        win.setContentSize(NSSize(width: 420, height: 320))
        win.center()
        win.delegate = self
        window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension SettingsPanel: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
