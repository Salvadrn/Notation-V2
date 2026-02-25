import Foundation

struct Notebook: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let userId: UUID
    var folderId: UUID?
    var title: String
    var coverColor: String
    var sortOrder: Int
    var version: Int
    var isFavorite: Bool
    var isDeleted: Bool
    var deletedAt: Date?
    var template: String?
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case folderId = "folder_id"
        case title
        case coverColor = "cover_color"
        case sortOrder = "sort_order"
        case version
        case isFavorite = "is_favorite"
        case isDeleted = "is_deleted"
        case deletedAt = "deleted_at"
        case template
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Days remaining before auto-purge (30 day retention)
    var daysUntilPurge: Int? {
        guard isDeleted, let deletedAt else { return nil }
        let elapsed = Calendar.current.dateComponents([.day], from: deletedAt, to: Date()).day ?? 0
        return max(0, 30 - elapsed)
    }

    /// Whether this notebook should be auto-purged
    var shouldPurge: Bool {
        guard let days = daysUntilPurge else { return false }
        return days <= 0
    }

    static func new(userId: UUID, folderId: UUID? = nil, title: String = "Untitled Notebook") -> Notebook {
        Notebook(
            id: UUID(),
            userId: userId,
            folderId: folderId,
            title: title,
            coverColor: "#6366F1",
            sortOrder: 0,
            version: 1,
            isFavorite: false,
            isDeleted: false,
            deletedAt: nil,
            template: nil,
            createdAt: nil,
            updatedAt: nil
        )
    }
}
