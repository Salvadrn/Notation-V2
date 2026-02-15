import Foundation
import Supabase

@MainActor
final class SectionService {
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

    func fetchSections(notebookId: UUID) async throws -> [Section] {
        let sections: [Section] = try await supabase.client
            .from("sections")
            .select()
            .eq("notebook_id", value: notebookId.uuidString)
            .order("sort_order")
            .execute()
            .value
        return sections
    }

    func createSection(notebookId: UUID, title: String = "Untitled Section") async throws -> Section {
        let uid = try userId
        let section = Section.new(notebookId: notebookId, userId: uid, title: title)
        try await supabase.client
            .from("sections")
            .insert(section)
            .execute()
        return section
    }

    func updateSection(_ section: Section) async throws {
        try await supabase.client
            .from("sections")
            .update(section)
            .eq("id", value: section.id.uuidString)
            .execute()
    }

    func deleteSection(id: UUID) async throws {
        try await supabase.client
            .from("sections")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func reorderSections(_ sections: [Section]) async throws {
        for (index, var section) in sections.enumerated() {
            section.sortOrder = index
            try await supabase.client
                .from("sections")
                .update(["sort_order": index])
                .eq("id", value: section.id.uuidString)
                .execute()
        }
    }
}
