import Foundation
import Supabase

@MainActor
final class AIService {
    private let supabase: SupabaseService
    private let storageService: StorageService
    private let tokenService: TokenService

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

        // Check token balance
        let hasTokens = try await tokenService.hasEnoughTokens(for: Constants.Tokens.costPerAIGeneration)
        guard hasTokens else { throw NotationError.insufficientTokens }

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
            tokensUsed: 0,
            status: .processing,
            createdAt: nil
        )

        try await supabase.client
            .from("ai_jobs")
            .insert(job)
            .execute()

        do {
            // Call Claude API
            let base64Image = imageData.base64EncodedString()
            let notes = try await callClaudeAPI(base64Image: base64Image)

            // Update job with results
            job.outputNotes = notes
            job.status = .completed
            job.tokensUsed = Constants.Tokens.costPerAIGeneration

            try await supabase.client
                .from("ai_jobs")
                .update(job)
                .eq("id", value: job.id.uuidString)
                .execute()

            // Deduct tokens
            try await tokenService.deductTokens(
                amount: Constants.Tokens.costPerAIGeneration,
                reason: "AI note generation",
                referenceId: job.id.uuidString
            )

            return notes
        } catch {
            // Mark job as failed
            job.status = .failed
            try? await supabase.client
                .from("ai_jobs")
                .update(["status": "failed"])
                .eq("id", value: job.id.uuidString)
                .execute()
            throw error
        }
    }

    private func callClaudeAPI(base64Image: String) async throws -> AIGeneratedNotes {
        let requestBody: [String: Any] = [
            "model": AppConfig.claudeModel,
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/png",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            Analyze this slide or image and create structured study notes. Return a JSON object with this exact structure:
                            {
                              "title": "Main title or topic",
                              "summary": "Brief 2-3 sentence summary",
                              "sections": [
                                {
                                  "heading": "Section heading",
                                  "bullets": ["Key point 1", "Key point 2"]
                                }
                              ],
                              "keyDefinitions": [
                                {
                                  "term": "Important term",
                                  "definition": "Clear definition"
                                }
                              ]
                            }
                            Return ONLY the JSON, no other text.
                            """
                        ]
                    ]
                ]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: AppConfig.claudeAPIURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NotationError.networkError("Claude API request failed")
        }

        // Parse Claude response
        let claudeResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = claudeResponse?["content"] as? [[String: Any]],
              let textBlock = content.first(where: { $0["type"] as? String == "text" }),
              let text = textBlock["text"] as? String else {
            throw NotationError.unknown("Failed to parse Claude response")
        }

        // Parse the JSON from Claude's response
        guard let notesData = text.data(using: .utf8) else {
            throw NotationError.unknown("Failed to encode notes text")
        }

        let decoder = JSONDecoder()
        let notes = try decoder.decode(AIGeneratedNotes.self, from: notesData)
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
