import Foundation
import Supabase

@MainActor
final class NotebookService {
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

    func fetchNotebooks(folderId: UUID?) async throws -> [Notebook] {
        let uid = try userId
        var query = supabase.client
            .from("notebooks")
            .select()
            .eq("user_id", value: uid.uuidString)

        if let folderId {
            query = query.eq("folder_id", value: folderId.uuidString)
        } else {
            query = query.is("folder_id", value: nil)
        }

        let notebooks: [Notebook] = try await query
            .order("sort_order")
            .execute()
            .value
        return notebooks
    }

    func fetchAllNotebooks() async throws -> [Notebook] {
        let uid = try userId
        let notebooks: [Notebook] = try await supabase.client
            .from("notebooks")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
        return notebooks
    }

    func createNotebook(title: String, folderId: UUID? = nil) async throws -> Notebook {
        let uid = try userId
        let notebook = Notebook.new(userId: uid, folderId: folderId, title: title)
        try await supabase.client
            .from("notebooks")
            .insert(notebook)
            .execute()
        return notebook
    }

    func updateNotebook(_ notebook: Notebook) async throws {
        try await supabase.client
            .from("notebooks")
            .update(notebook)
            .eq("id", value: notebook.id.uuidString)
            .execute()
    }

    func deleteNotebook(id: UUID) async throws {
        try await supabase.client
            .from("notebooks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func moveNotebook(_ notebookId: UUID, toFolder folderId: UUID?) async throws {
        struct NotebookMove: Encodable {
            let folderId: UUID?
            enum CodingKeys: String, CodingKey {
                case folderId = "folder_id"
            }
        }

        try await supabase.client
            .from("notebooks")
            .update(NotebookMove(folderId: folderId))
            .eq("id", value: notebookId.uuidString)
            .execute()
    }

    func notebookCount() async throws -> Int {
        let uid = try userId
        let notebooks: [Notebook] = try await supabase.client
            .from("notebooks")
            .select()
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return notebooks.count
    }
}
