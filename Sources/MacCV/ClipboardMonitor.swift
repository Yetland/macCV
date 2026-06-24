import AppKit

extension Notification.Name {
    static let clipboardDidUpdate = Notification.Name("clipboardDidUpdate")
}

final class ClipboardMonitor: @unchecked Sendable {
    private var lastChangeCount: Int
    private var isRunning = false
    private let database: Database
    nonisolated(unsafe) static var skipNext = false

    init(database: Database) {
        self.database = database
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        poll()
    }

    func stop() {
        isRunning = false
    }

    private func poll() {
        guard isRunning else { return }

        let pb = NSPasteboard.general
        let currentCount = pb.changeCount

        if currentCount != lastChangeCount {
            lastChangeCount = currentCount

            if Self.skipNext {
                Self.skipNext = false
                // self-caused change, don't record
            } else if let pbTypes = pb.types {
                if pbTypes.contains(.string) {
                    if let string = pb.string(forType: .string), !string.isEmpty {
                        database.insertText(string)
                        NotificationCenter.default.post(name: .clipboardDidUpdate, object: nil)
                    }
                } else if pbTypes.contains(.png), let data = pb.data(forType: .png) {
                    database.insertImage(data: data)
                    NotificationCenter.default.post(name: .clipboardDidUpdate, object: nil)
                } else if pbTypes.contains(NSPasteboard.PasteboardType("public.tiff")), let data = pb.data(forType: .tiff) {
                    database.insertImage(data: data)
                    NotificationCenter.default.post(name: .clipboardDidUpdate, object: nil)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.poll()
        }
    }
}
