import Foundation
import Supabase

@MainActor
final class StorageService {
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

    // MARK: - Upload

    func uploadImage(bucket: String, data: Data, fileName: String? = nil) async throws -> String {
        let uid = try userId
        let name = fileName ?? "\(UUID().uuidString).png"
        let path = "\(uid.uuidString)/\(name)"

        try await supabase.client.storage
            .from(bucket)
            .upload(
                path: path,
                file: data,
                options: FileOptions(contentType: "image/png", upsert: true)
            )

        return path
    }

    func uploadPDF(data: Data, fileName: String? = nil) async throws -> String {
        let uid = try userId
        let name = fileName ?? "\(UUID().uuidString).pdf"
        let path = "\(uid.uuidString)/\(name)"

        try await supabase.client.storage
            .from(AppConfig.attachmentsBucket)
            .upload(
                path: path,
                file: data,
                options: FileOptions(contentType: "application/pdf", upsert: true)
            )

        return path
    }

    func uploadData(bucket: String, data: Data, path: String, contentType: String) async throws -> String {
        try await supabase.client.storage
            .from(bucket)
            .upload(
                path: path,
                file: data,
                options: FileOptions(contentType: contentType, upsert: true)
            )

        return path
    }

    // MARK: - Download

    func downloadData(bucket: String, path: String) async throws -> Data {
        let data = try await supabase.client.storage
            .from(bucket)
            .download(path: path)
        return data
    }

    // MARK: - Public URL

    func publicURL(bucket: String, path: String) throws -> URL {
        try supabase.client.storage
            .from(bucket)
            .getPublicURL(path: path)
    }

    // MARK: - Delete

    func deleteFile(bucket: String, path: String) async throws {
        try await supabase.client.storage
            .from(bucket)
            .remove(paths: [path])
    }

    // MARK: - List

    func listFiles(bucket: String, path: String) async throws -> [FileObject] {
        try await supabase.client.storage
            .from(bucket)
            .list(path: path)
    }
}
