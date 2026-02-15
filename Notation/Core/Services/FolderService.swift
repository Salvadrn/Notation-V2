import Foundation
import Supabase

@MainActor
final class FolderService {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    private var userId: UUID {
        get throws {
            guard let id = supabase.currentUserId else {
                throw NotationError.notAuthenticated
            }
            return id
        }
    }

    func fetchFolders() async throws -> [Folder] {
        let uid = try userId
        let folders: [Folder] = try await supabase.client
            .from("folders")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("sort_order")
            .execute()
            .value
        return folders
    }

    func fetchSubfolders(parentId: UUID) async throws -> [Folder] {
        let uid = try userId
        let folders: [Folder] = try await supabase.client
            .from("folders")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("parent_id", value: parentId.uuidString)
            .order("sort_order")
            .execute()
            .value
        return folders
    }

    func fetchRootFolders() async throws -> [Folder] {
        let uid = try userId
        let folders: [Folder] = try await supabase.client
            .from("folders")
            .select()
            .eq("user_id", value: uid.uuidString)
            .is("parent_id", value: nil)
            .order("sort_order")
            .execute()
            .value
        return folders
    }

    func createFolder(name: String, parentId: UUID? = nil, parentPath: String = "") async throws -> Folder {
        let uid = try userId
        let folder = Folder.new(userId: uid, name: name, parentId: parentId, parentPath: parentPath)
        try await supabase.client
            .from("folders")
            .insert(folder)
            .execute()
        return folder
    }

    func updateFolder(_ folder: Folder) async throws {
        try await supabase.client
            .from("folders")
            .update(folder)
            .eq("id", value: folder.id.uuidString)
            .execute()
    }

    func deleteFolder(id: UUID) async throws {
        try await supabase.client
            .from("folders")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func moveFolder(_ folderId: UUID, toParent parentId: UUID?, parentPath: String) async throws {
        let uid = try userId
        let newPath = parentPath.isEmpty
            ? "/\(folderId.uuidString)/"
            : "\(parentPath)\(folderId.uuidString)/"

        struct FolderUpdate: Encodable {
            let parentId: UUID?
            let path: String

            enum CodingKeys: String, CodingKey {
                case parentId = "parent_id"
                case path
            }
        }

        try await supabase.client
            .from("folders")
            .update(FolderUpdate(parentId: parentId, path: newPath))
            .eq("id", value: folderId.uuidString)
            .eq("user_id", value: uid.uuidString)
            .execute()
    }
}
