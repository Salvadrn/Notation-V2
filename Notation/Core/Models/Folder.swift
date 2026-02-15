import Foundation

struct Folder: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let userId: UUID
    var parentId: UUID?
    var name: String
    var path: String
    var sortOrder: Int
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case parentId = "parent_id"
        case name
        case path
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var depth: Int {
        path.components(separatedBy: "/").filter { !$0.isEmpty }.count
    }

    static func new(userId: UUID, name: String, parentId: UUID? = nil, parentPath: String = "") -> Folder {
        let id = UUID()
        let newPath = parentPath.isEmpty ? "/\(id.uuidString)/" : "\(parentPath)\(id.uuidString)/"
        return Folder(
            id: id,
            userId: userId,
            parentId: parentId,
            name: name,
            path: newPath,
            sortOrder: 0,
            createdAt: nil,
            updatedAt: nil
        )
    }
}
