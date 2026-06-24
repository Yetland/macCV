import Foundation
import GRDB
import CommonCrypto
import AppKit

enum DatabaseError: Error {
    case notFound
    case imageStorageFailed(String)
}

final class Database: @unchecked Sendable {
    private var dbQueue: DatabaseQueue?
    private let imageDir: URL

    static let shared = Database()

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dbDir = appSupport.appendingPathComponent("MacCV", isDirectory: true)
        imageDir = dbDir.appendingPathComponent("Images", isDirectory: true)
        dbQueue = nil

        do {
            try FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: imageDir, withIntermediateDirectories: true)

            let dbPath = dbDir.appendingPathComponent("db.sqlite").path
            let queue = try DatabaseQueue(path: dbPath)
            try migrator.migrate(queue)
            dbQueue = queue
        } catch {
            print("[MacCV] Database init error: \(error)")
        }
    }

    // MARK: - Migration

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "history_items", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("type", .text).notNull()
                t.column("content", .text)
                t.column("imagePath", .text)
                t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }
        }
        migrator.registerMigration("v2") { db in
            try db.create(virtualTable: "history_items_fts", using: FTS5()) { t in
                t.content = "history_items"
                t.column("content")
                t.tokenizer = .unicode61()
            }
            try db.execute(sql: """
                INSERT INTO history_items_fts(rowid, content)
                SELECT rowid, content FROM history_items WHERE type = 'text'
            """)
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS history_items_ai AFTER INSERT ON history_items BEGIN
                    INSERT INTO history_items_fts(rowid, content) VALUES (new.rowid, new.content);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS history_items_ad AFTER DELETE ON history_items BEGIN
                    INSERT INTO history_items_fts(history_items_fts, rowid, content) VALUES('delete', old.rowid, old.content);
                END
            """)
        }
        return migrator
    }

    // MARK: - Read

    func fetchItems(search: String? = nil, filterType: HistoryItem.ItemType? = nil, limit: Int = 500) -> [HistoryItem] {
        guard let dbQueue else { return [] }
        return (try? dbQueue.read { db in
            let terms = (search ?? "").trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }

            var sql = "SELECT * FROM history_items"
            var conditions: [String] = []
            var args: [any DatabaseValueConvertible] = []

            // LIKE-based search for universal language support (Chinese, etc.)
            for term in terms {
                conditions.append("content LIKE ?")
                args.append("%\(term)%")
            }

            if let filterType {
                conditions.append("type = ?")
                args.append(filterType.rawValue)
            }

            if !conditions.isEmpty {
                sql += " WHERE " + conditions.joined(separator: " AND ")
            }

            sql += " ORDER BY createdAt DESC LIMIT ?"
            args.append(limit)

            return try HistoryItem.fetchAll(db, sql: sql, arguments: StatementArguments(args))
        }) ?? []
    }

    func fetchItemCount() -> Int {
        guard let dbQueue else { return 0 }
        return (try? dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM history_items") ?? 0
        }) ?? 0
    }

    // MARK: - Write

    func insertText(_ text: String) {
        guard let dbQueue else { return }
        let lastText = try? dbQueue.read { db -> String? in
            try String.fetchOne(db, sql: """
                SELECT content FROM history_items WHERE type = 'text' ORDER BY createdAt DESC LIMIT 1
            """)
        }
        guard lastText != text else { return }

        let item = HistoryItem(id: nil, type: .text, content: text, imagePath: nil, createdAt: Date())
        try? dbQueue.write { db in
            try item.insert(db)
        }
        pruneIfNeeded()
    }

    func insertImage(data: Data) {
        guard let dbQueue else { return }
        let newHash = sha256String(data: data)

        let lastHash = try? dbQueue.read { db -> String? in
            try String.fetchOne(db, sql: """
                SELECT imagePath FROM history_items WHERE type = 'image' ORDER BY createdAt DESC LIMIT 1
            """)
        }
        if lastHash == newHash + ".png" { return }

        let fileURL = imageDir.appendingPathComponent("\(newHash).png")
        let nsImage = NSImage(data: data)
        if let nsImage, let pngData = nsImage.toPNGData() {
            try? pngData.write(to: fileURL, options: .atomic)
        } else {
            try? data.write(to: fileURL, options: .atomic)
        }

        let item = HistoryItem(id: nil, type: .image, content: nil, imagePath: newHash + ".png", createdAt: Date())
        try? dbQueue.write { db in
            try item.insert(db)
        }
        pruneIfNeeded()
    }

    func deleteItem(id: Int64) {
        guard let dbQueue else { return }
        try? dbQueue.write { db in
            if let item = try HistoryItem.fetchOne(db, key: id), item.type == .image, let path = item.imagePath {
                let fileURL = imageDir.appendingPathComponent(path)
                try? FileManager.default.removeItem(at: fileURL)
            }
            try HistoryItem.deleteOne(db, key: id)
        }
    }

    func deleteAll() {
        guard let dbQueue else { return }
        try? dbQueue.write { db in
            let images = try HistoryItem.filter(Column("type") == "image").fetchAll(db)
            for item in images {
                if let path = item.imagePath {
                    let fileURL = imageDir.appendingPathComponent(path)
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
            try HistoryItem.deleteAll(db)
        }
    }

    // MARK: - Pruning

    private func pruneIfNeeded() {
        guard let dbQueue else { return }
        let saved = UserDefaults.standard.integer(forKey: "maxHistory")
        let maxItems = saved > 0 ? saved : 1000
        try? dbQueue.write { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM history_items") ?? 0
            if count > maxItems {
                let excess = count - maxItems
                let old = try HistoryItem
                    .order(Column("createdAt").asc)
                    .limit(excess)
                    .fetchAll(db)
                for item in old {
                    if item.type == .image, let path = item.imagePath {
                        let fileURL = imageDir.appendingPathComponent(path)
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                    try item.delete(db)
                }
            }
        }
    }

    // MARK: - Image path

    func imageURL(for path: String) -> URL {
        imageDir.appendingPathComponent(path)
    }
}

// MARK: - Helpers

private func sha256String(data: Data) -> String {
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes { buf in
        _ = CC_SHA256(buf.baseAddress, CC_LONG(data.count), &hash)
    }
    return hash.map { String(format: "%02x", $0) }.joined()
}

extension NSImage {
    func toPNGData() -> Data? {
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
