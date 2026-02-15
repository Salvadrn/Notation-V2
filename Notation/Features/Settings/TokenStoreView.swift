import SwiftUI
import StoreKit

struct TokenStoreView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var purchasedAmount: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Theme.Colors.primaryFallback)

                        Text("Buy Tokens")
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Tokens are used for AI note generation and handwriting conversion")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.xxl)

                    // Token cost breakdown
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        tokenCostRow("AI Note Generation", cost: Constants.Tokens.costPerAIGeneration)
                        tokenCostRow("Handwriting Conversion", cost: Constants.Tokens.costPerHandwritingConversion)
                    }
                    .padding(Theme.Spacing.lg)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Token packs
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(subscriptionService.tokenProducts, id: \.id) { product in
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

                    if let amount = purchasedAmount {
                        Text("Successfully added \(amount) tokens!")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.success)
                    }
                }
            }
            .navigationTitle("Token Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onFirstAppear {
                await subscriptionService.loadProducts()
            }
        }
    }

    @ViewBuilder
    private func tokenCostRow(_ feature: String, cost: Int) -> some View {
        HStack {
            Text(feature)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            Text("\(cost) tokens")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.primaryFallback)
                .fontWeight(.medium)
        }
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        do {
            let transaction = try await subscriptionService.purchase(product)
            if transaction != nil {
                // Determine token amount from product ID
                let amount: Int
                switch product.id {
                case Constants.Products.tokenPack100: amount = 100
                case Constants.Products.tokenPack500: amount = 500
                case Constants.Products.tokenPack1000: amount = 1000
                default: amount = 0
                }

                if amount > 0 {
                    let tokenService = TokenService()
                    try await tokenService.addTokens(
                        amount: amount,
                        reason: "Token purchase: \(product.displayName)",
                        referenceId: String(transaction!.id)
                    )
                    purchasedAmount = amount
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }
}
