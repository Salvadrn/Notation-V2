import Foundation

struct Section: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let notebookId: UUID
    let userId: UUID
    var title: String
    var sortOrder: Int
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case notebookId = "notebook_id"
        case userId = "user_id"
        case title
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func new(notebookId: UUID, userId: UUID, title: String = "Untitled Section") -> Section {
        Section(
            id: UUID(),
            notebookId: notebookId,
            userId: userId,
            title: title,
            sortOrder: 0,
            createdAt: nil,
            updatedAt: nil
        )
    }
}
