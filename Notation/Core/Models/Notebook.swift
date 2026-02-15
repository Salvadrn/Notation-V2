import Foundation

struct Notebook: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let userId: UUID
    var folderId: UUID?
    var title: String
    var coverColor: String
    var sortOrder: Int
    var version: Int
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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
            createdAt: nil,
            updatedAt: nil
        )
    }
}
