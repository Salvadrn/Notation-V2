import Foundation

@MainActor
final class FeatureGate: ObservableObject {
    private let supabase: SupabaseService
    private let subscriptionService: SubscriptionService

    @Published var currentTier: SubscriptionTier = .free

    init(supabase: SupabaseService = .shared, subscriptionService: SubscriptionService) {
        self.supabase = supabase
        self.subscriptionService = subscriptionService
    }

    func refreshTier() async {
        if subscriptionService.isProUser {
            currentTier = .pro
        } else {
            currentTier = .free
        }
    }

    // MARK: - Notebooks

    func canCreateNotebook(currentCount: Int) -> Bool {
        switch currentTier {
        case .free:
            return currentCount < Constants.FreeTier.maxNotebooks
        case .pro:
            return true
        }
    }

    var maxNotebooks: Int {
        switch currentTier {
        case .free: return Constants.FreeTier.maxNotebooks
        case .pro: return Int.max
        }
    }

    // MARK: - AI

    var canUseAI: Bool {
        currentTier == .pro
    }

    // MARK: - Handwriting Conversion

    func canConvert(currentMonthlyCount: Int) -> Bool {
        switch currentTier {
        case .free:
            return currentMonthlyCount < Constants.FreeTier.maxConversionsPerMonth
        case .pro:
            return true // Pro users have unlimited conversions
        }
    }

    var maxConversionsPerMonth: Int {
        switch currentTier {
        case .free: return Constants.FreeTier.maxConversionsPerMonth
        case .pro: return Int.max
        }
    }

    // MARK: - Pages Per Notebook

    func canAddPage(currentCount: Int) -> Bool {
        switch currentTier {
        case .free:
            return currentCount < Constants.FreeTier.maxPagesPerNotebook
        case .pro:
            return true
        }
    }

    // MARK: - Collaboration

    var canCollaborate: Bool {
        currentTier == .pro
    }

    // MARK: - Display Helpers

    func limitMessage(for feature: String) -> String {
        switch currentTier {
        case .free:
            return "Upgrade to Pro to unlock unlimited \(feature)."
        case .pro:
            return "You've reached the monthly limit for \(feature)."
        }
    }
}
