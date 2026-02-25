import SwiftUI

@main
struct NotationApp: App {
    @StateObject private var supabase = SupabaseService.shared
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var realtimeService = RealtimeService()
    @StateObject private var errorHandler = ErrorHandler.shared

    init() {
        configureAppearance()
        // Apply saved appearance mode
        AppearanceManager.shared.applyAppearance()
    }

    var body: some Scene {
        WindowGroup {
            AuthGateView(supabase: supabase)
                .environmentObject(supabase)
                .environmentObject(subscriptionService)
                .environmentObject(realtimeService)
                .environmentObject(errorHandler)
                .withErrorHandling(errorHandler)
                .onOpenURL { url in
                    // Handle magic link callback
                    Task {
                        do {
                            try await supabase.client.auth.session(from: url)
                            await supabase.restoreSession()
                            supabase.observeAuthChanges()
                            supabase.completeOnboarding()
                        } catch {
                            print("[MagicLink] Failed to handle callback: \(error)")
                        }
                    }
                }
                .task {
                    // In guest mode, skip Supabase auth calls
                    if !supabase.isGuestMode && supabase.isSupabaseConfigured {
                        await supabase.restoreSession()
                        supabase.observeAuthChanges()
                    }
                }
                .task {
                    // Load StoreKit products independently — don't block auth flow
                    await subscriptionService.loadProducts()
                    await subscriptionService.restorePurchases()
                }
        }
    }

    /// Sets Aptos as the default font for UIKit-backed components (navigation bars, lists, etc.)
    private func configureAppearance() {
        #if os(iOS)
        // Navigation bar title fonts
        if let aptosLargeTitle = UIFont(name: "Aptos-Bold", size: 34) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: aptosLargeTitle]
        }
        if let aptosTitle = UIFont(name: "Aptos-Bold", size: 17) {
            UINavigationBar.appearance().titleTextAttributes = [.font: aptosTitle]
        }
        #endif
    }
}
