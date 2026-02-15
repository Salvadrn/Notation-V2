import Foundation
import Combine
import Supabase

@MainActor
final class PageService {
    private let supabase: SupabaseService
    private var autosaveTask: Task<Void, Never>?
    private var pendingSave: Page?

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

    func fetchPages(sectionId: UUID) async throws -> [Page] {
        let pages: [Page] = try await supabase.client
            .from("pages")
            .select()
            .eq("section_id", value: sectionId.uuidString)
            .order("sort_order")
            .execute()
            .value
        return pages
    }

    func fetchPage(id: UUID) async throws -> Page {
        let page: Page = try await supabase.client
            .from("pages")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        return page
    }

    func createPage(sectionId: UUID, sortOrder: Int = 0) async throws -> Page {
        let uid = try userId
        let page = Page.new(sectionId: sectionId, userId: uid, sortOrder: sortOrder)
        try await supabase.client
            .from("pages")
            .insert(page)
            .execute()
        return page
    }

    func updatePage(_ page: Page) async throws {
        var updated = page
        updated.version += 1
        try await supabase.client
            .from("pages")
            .update(updated)
            .eq("id", value: page.id.uuidString)
            .execute()
    }

    func deletePage(id: UUID) async throws {
        try await supabase.client
            .from("pages")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // Debounced autosave: schedules a save after the debounce interval
    func scheduleSave(page: Page) {
        pendingSave = page
        autosaveTask?.cancel()
        autosaveTask = Task {
            try? await Task.sleep(for: .seconds(Constants.Autosave.debounceInterval))
            guard !Task.isCancelled, let pageToSave = pendingSave else { return }
            try? await updatePage(pageToSave)
            pendingSave = nil
        }
    }

    func flushPendingSave() async {
        autosaveTask?.cancel()
        if let page = pendingSave {
            try? await updatePage(page)
            pendingSave = nil
        }
    }

    func reorderPages(_ pages: [Page]) async throws {
        for (index, page) in pages.enumerated() {
            try await supabase.client
                .from("pages")
                .update(["sort_order": index])
                .eq("id", value: page.id.uuidString)
                .execute()
        }
    }
}
