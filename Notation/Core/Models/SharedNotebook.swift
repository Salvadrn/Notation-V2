import Foundation

enum SharePermission: String, Codable {
    case view
    case edit
}

struct SharedNotebook: Codable, Identifiable, Equatable {
    let id: UUID
    let notebookId: UUID
    let ownerId: UUID
    let sharedWithId: UUID
    var permission: SharePermission
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case notebookId = "notebook_id"
        case ownerId = "owner_id"
        case sharedWithId = "shared_with_id"
        case permission
        case createdAt = "created_at"
    }
}
