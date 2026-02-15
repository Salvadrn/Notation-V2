import Foundation

enum AppConfig {
    // MARK: - Supabase
    // Replace these with your Supabase project values
    static let supabaseURL = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"

    // MARK: - Claude API
    // Replace with your Anthropic API key
    static let claudeAPIKey = "YOUR_CLAUDE_API_KEY"
    static let claudeAPIURL = URL(string: "https://api.anthropic.com/v1/messages")!
    static let claudeModel = "claude-sonnet-4-5-20250929"

    // MARK: - Storage Buckets
    static let avatarsBucket = "avatars"
    static let glyphsBucket = "glyphs"
    static let attachmentsBucket = "attachments"
    static let exportsBucket = "exports"

    // MARK: - Feature Flags
    static let enableRealtime = true
    static let enableOfflineMode = true
    static let enableAI = true
}
