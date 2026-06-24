import Foundation
import GRDB

struct HistoryItem: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var type: ItemType
    var content: String?
    var imagePath: String?
    var createdAt: Date

    enum ItemType: String, Codable, CaseIterable {
        case text
        case image
    }

    enum CodingKeys: String, CodingKey {
        case id, type, content, imagePath, createdAt
    }

    static let databaseTableName = "history_items"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct HistoryItemFTS: Codable, FetchableRecord, PersistableRecord {
    var rowid: Int64
    var content: String?
}
