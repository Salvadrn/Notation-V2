import SwiftUI

@main
struct NotationApp: App {
    @StateObject private var supabase = SupabaseService.shared
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var realtimeService = RealtimeService()
    @StateObject private var errorHandler = ErrorHandler.shared

    var body: some Scene {
        WindowGroup {
            AuthGateView(supabase: supabase)
                .environmentObject(supabase)
                .environmentObject(subscriptionService)
                .environmentObject(realtimeService)
                .environmentObject(errorHandler)
                .withErrorHandling(errorHandler)
                .task {
                    await supabase.restoreSession()
                    supabase.observeAuthChanges()
                    await subscriptionService.loadProducts()
                    await subscriptionService.restorePurchases()
                }
        }
    }
}
