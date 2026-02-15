import Foundation

struct ClaudeAPIClient {
    struct Message: Encodable {
        let role: String
        let content: [ContentBlock]
    }

    enum ContentBlock: Encodable {
        case text(String)
        case image(mediaType: String, data: String)

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .text)
            case .image(let mediaType, let data):
                try container.encode("image", forKey: .type)
                var sourceContainer = container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source)
                try sourceContainer.encode("base64", forKey: .type)
                try sourceContainer.encode(mediaType, forKey: .mediaType)
                try sourceContainer.encode(data, forKey: .data)
            }
        }

        enum CodingKeys: String, CodingKey {
            case type, text, source
        }

        enum SourceKeys: String, CodingKey {
            case type
            case mediaType = "media_type"
            case data
        }
    }

    struct Request: Encodable {
        let model: String
        let maxTokens: Int
        let messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case messages
        }
    }

    struct Response: Decodable {
        let content: [ResponseContent]
    }

    struct ResponseContent: Decodable {
        let type: String
        let text: String?
    }

    static func sendRequest(
        messages: [Message],
        maxTokens: Int = 4096
    ) async throws -> String {
        let request = Request(
            model: AppConfig.claudeModel,
            maxTokens: maxTokens,
            messages: messages
        )

        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(request)

        var urlRequest = URLRequest(url: AppConfig.claudeAPIURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(AppConfig.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotationError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NotationError.networkError("Claude API error (\(httpResponse.statusCode)): \(errorBody)")
        }

        let claudeResponse = try JSONDecoder().decode(Response.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
              let text = textContent.text else {
            throw NotationError.unknown("No text in Claude response")
        }

        return text
    }

    /// Convenience: analyze an image and return structured notes
    static func analyzeImage(base64Data: String, mediaType: String = "image/png") async throws -> String {
        let messages: [Message] = [
            Message(role: "user", content: [
                .image(mediaType: mediaType, data: base64Data),
                .text("""
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
                Return ONLY valid JSON, no other text.
                """)
            ])
        ]

        return try await sendRequest(messages: messages)
    }
}
