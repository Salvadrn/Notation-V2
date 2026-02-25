import Foundation

enum AppConfig {
    // MARK: - Supabase
    // Replace these with your Supabase project values
    static let supabaseURL = URL(string: "https://gkoqghnmlodfbfaiktjm.supabase.co")!
    static let supabaseAnonKey = "sb_publishable_8hnyUQRNdY6YkkB2fnS0qg_HbBDa5ul"

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
