import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Theme.Colors.accent)

                        Text("Notation Pro")
                            .font(Theme.Typography.largeTitle)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Unlock the full power of Notation")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.top, Theme.Spacing.xxl)

                    // Features
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        featureRow("Unlimited notebooks", icon: "book.closed.fill")
                        featureRow("AI-powered note generation", icon: "sparkles")
                        featureRow("Real-time collaboration", icon: "person.2.fill")
                        featureRow("50 handwriting conversions/month", icon: "hand.draw.fill")
                        featureRow("Priority cloud sync", icon: "icloud.fill")
                        featureRow("PDF export", icon: "doc.fill")
                    }
                    .padding(Theme.Spacing.lg)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Products
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(subscriptionService.subscriptionProducts, id: \.id) { product in
                            Button {
                                Task { await purchase(product) }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.displayName)
                                            .font(Theme.Typography.headline)
                                            .foregroundStyle(Theme.Colors.textPrimary)
                                        Text(product.description)
                                            .font(Theme.Typography.caption)
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                    }

                                    Spacer()

                                    Text(product.displayPrice)
                                        .font(Theme.Typography.title3)
                                        .foregroundStyle(Theme.Colors.primaryFallback)
                                }
                                .padding(Theme.Spacing.lg)
                                .background(Theme.Colors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                                        .strokeBorder(Theme.Colors.primaryFallback.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isPurchasing)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    if let error = errorMessage {
                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.destructive)
                    }

                    // Restore
                    Button("Restore Purchases") {
                        Task { await subscriptionService.restorePurchases() }
                    }
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()
                }
            }
            .navigationTitle("Go Pro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onFirstAppear {
                await subscriptionService.loadProducts()
            }
        }
    }

    @ViewBuilder
    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 24)

            Text(text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        do {
            _ = try await subscriptionService.purchase(product)
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }
}
