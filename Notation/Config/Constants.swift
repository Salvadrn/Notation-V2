import Foundation
import CoreGraphics

enum Constants {
    // MARK: - Page Sizes (in points, 72 dpi)
    enum PageSize {
        static let a4 = CGSize(width: 595, height: 842)
        static let letter = CGSize(width: 612, height: 792)

        static func size(for type: PageSizeType) -> CGSize {
            switch type {
            case .a4: return a4
            case .letter: return letter
            }
        }
    }

    // MARK: - Free Tier Limits
    enum FreeTier {
        static let maxNotebooks = 3
        static let maxConversionsPerMonth = 5
        static let maxAIUsesPerMonth = 0
        static let maxPagesPerNotebook = 50
    }

    // MARK: - Pro Tier Limits
    enum ProTier {
        static let maxConversionsPerMonth = 50
        static let maxAIUsesPerMonth = -1 // unlimited
        static let maxPagesPerNotebook = -1 // unlimited
    }

    // MARK: - Token Pricing
    enum Tokens {
        static let costPerAIGeneration = 10
        static let costPerHandwritingConversion = 2
        static let starterPackAmount = 100
        // Prices set in App Store Connect
    }

    // MARK: - StoreKit Product IDs
    enum Products {
        static let proMonthly = "com.sdnotation.pro.monthly"
        static let proYearly = "com.sdnotation.pro.yearly"
        static let tokenPack100 = "com.sdnotation.tokens.100"
        static let tokenPack500 = "com.sdnotation.tokens.500"
        static let tokenPack1000 = "com.sdnotation.tokens.1000"
    }

    // MARK: - Autosave
    enum Autosave {
        static let debounceInterval: TimeInterval = 1.5
        static let maxRetries = 3
    }

    // MARK: - Realtime
    enum Realtime {
        static let channelPrefix = "notebook:"
        static let presenceKey = "user"
        static let heartbeatInterval: TimeInterval = 30
    }

    // MARK: - Handwriting
    enum Handwriting {
        static let baseCharacterSize = CGSize(width: 40, height: 50)
        static let letterSpacing: CGFloat = 2
        static let wordSpacing: CGFloat = 14
        static let lineHeight: CGFloat = 60
        static let maxVariations = 5
    }

    // MARK: - Alphabet Characters
    static let uppercaseLetters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    static let lowercaseLetters = Array("abcdefghijklmnopqrstuvwxyz")
    static let digits = Array("0123456789")
    static let accentedCharacters = Array("áéíóúñüÁÉÍÓÚÑÜàèìòùâêîôûäëïöüçßÀÈÌÒÙÂÊÎÔÛÄËÏÖÜÇ")
    static let punctuation = Array(".,;:!?'\"()-@#&")

    static var allCharacters: [Character] {
        uppercaseLetters + lowercaseLetters + digits + accentedCharacters + punctuation
    }
}

enum PageSizeType: String, Codable, CaseIterable {
    case a4
    case letter

    var displayName: String {
        switch self {
        case .a4: return "A4"
        case .letter: return "Letter"
        }
    }
}

enum PageOrientation: String, Codable, CaseIterable {
    case portrait
    case landscape

    var displayName: String {
        switch self {
        case .portrait: return "Portrait"
        case .landscape: return "Landscape"
        }
    }
}
