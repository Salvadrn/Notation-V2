import Foundation
import Supabase

@MainActor
final class AIService {
    private let supabase: SupabaseService
    private let storageService: StorageService
    private let tokenService: TokenService

    /// Client-side rate limiting: min seconds between requests
    private static var lastRequestTime: Date?
    private static let minRequestInterval: TimeInterval = 5

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
        self.storageService = StorageService(supabase: supabase)
        self.tokenService = TokenService(supabase: supabase)
    }

    private var userId: UUID {
        get throws {
            guard let id = supabase.currentUserId else {
                throw NotationError.notAuthenticated
            }
            return id
        }
    }

    func generateNotesFromImage(imageData: Data, pageId: UUID?) async throws -> AIGeneratedNotes {
        let uid = try userId

        // Block guest users from using AI
        guard !supabase.isGuestMode else {
            throw NotationError.freeTierLimit("AI notes (sign in and upgrade to Pro)")
        }

        // Client-side rate limiting
        if let lastTime = Self.lastRequestTime,
           Date().timeIntervalSince(lastTime) < Self.minRequestInterval {
            throw NotationError.unknown("Please wait a few seconds before generating again.")
        }
        Self.lastRequestTime = Date()

        // Validate image size (max 5MB)
        guard imageData.count <= 5_242_880 else {
            throw NotationError.unknown("Image is too large. Maximum size is 5MB.")
        }

        // Deduct tokens BEFORE generating — pay first, then serve
        try await tokenService.deductTokens(
            amount: Constants.Tokens.costPerAIGeneration,
            reason: "AI note generation",
            referenceId: nil
        )

        // Upload image to storage
        let imagePath = try await storageService.uploadImage(
            bucket: AppConfig.attachmentsBucket,
            data: imageData,
            fileName: "ai_input_\(UUID().uuidString).png"
        )

        // Create AI job record
        var job = AIJob(
            id: UUID(),
            userId: uid,
            pageId: pageId,
            inputType: .image,
            inputUrl: imagePath,
            outputNotes: nil,
            tokensUsed: Constants.Tokens.costPerAIGeneration,
            status: .processing,
            createdAt: nil
        )

        try await supabase.client
            .from("ai_jobs")
            .insert(job)
            .execute()

        do {
            // Call Claude via Edge Function
            let base64Image = imageData.base64EncodedString()
            let notes = try await callEdgeFunction(base64Image: base64Image)

            // Update job with results
            job.outputNotes = notes
            job.status = .completed

            try await supabase.client
                .from("ai_jobs")
                .update(job)
                .eq("id", value: job.id.uuidString)
                .execute()

            return notes
        } catch {
            // Mark job as failed and refund tokens
            job.status = .failed
            try? await supabase.client
                .from("ai_jobs")
                .update(["status": "failed"])
                .eq("id", value: job.id.uuidString)
                .execute()

            // Refund tokens on API failure (not user error)
            try? await tokenService.addTokens(
                amount: Constants.Tokens.costPerAIGeneration,
                reason: "Refund: AI generation failed",
                referenceId: job.id.uuidString
            )

            throw error
        }
    }

    private struct EdgeFunctionBody: Encodable {
        let image_base64: String
        let media_type: String
    }

    private func callEdgeFunction(base64Image: String) async throws -> AIGeneratedNotes {
        let body = EdgeFunctionBody(image_base64: base64Image, media_type: "image/png")

        let notes: AIGeneratedNotes = try await supabase.client.functions.invoke(
            "generate-notes",
            options: .init(body: body)
        )

        return notes
    }

    func fetchJobs() async throws -> [AIJob] {
        let uid = try userId
        let jobs: [AIJob] = try await supabase.client
            .from("ai_jobs")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return jobs
    }
}
