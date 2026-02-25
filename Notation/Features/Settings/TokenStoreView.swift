import SwiftUI
import StoreKit

struct TokenStoreView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var purchasedAmount: Int?
    @State private var customTokenAmount: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Theme.Colors.primaryFallback)

                        Text("Token Store")
                            .font(.custom("Aptos-Bold", size: 28))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Tokens power AI features. Buy packs or enter a custom amount.")
                            .font(.custom("Aptos", size: 15))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.xxl)

                    // Token cost breakdown
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Token Usage")
                            .font(.custom("Aptos-Bold", size: 15))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        tokenCostRow("AI Note Generation", cost: Constants.Tokens.costPerAIGeneration)
                        tokenCostRow("Handwriting Conversion", cost: Constants.Tokens.costPerHandwritingConversion)
                    }
                    .padding(Theme.Spacing.lg)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Token packs
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Token Packs")
                            .font(.custom("Aptos-Bold", size: 17))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.Spacing.lg)

                        ForEach(subscriptionService.tokenProducts, id: \.id) { product in
                            Button {
                                Task { await purchase(product) }
                            } label: {
                                tokenPackRow(product: product)
                            }
                            .buttonStyle(.plain)
                            .disabled(isPurchasing)
                        }

                        // If no products loaded, show placeholder packs
                        if subscriptionService.tokenProducts.isEmpty {
                            placeholderTokenPack(name: "100 Tokens", description: "~10 AI generations", price: "$0.99")
                            placeholderTokenPack(name: "500 Tokens", description: "~50 AI generations", price: "$2.99")
                            placeholderTokenPack(name: "1,000 Tokens", description: "~100 AI generations", price: "$4.99")
                            placeholderTokenPack(name: "2,500 Tokens", description: "~250 AI generations — Best value!", price: "$9.99")
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Custom amount
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Custom Amount")
                            .font(.custom("Aptos-Bold", size: 17))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "number")
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                TextField("Enter tokens", text: $customTokenAmount)
                                    .textFieldStyle(.plain)
                                    .font(.custom("Aptos", size: 16))
                                    #if os(iOS)
                                    .keyboardType(.numberPad)
                                    #endif
                            }
                            .padding(12)
                            .background(Theme.Colors.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            Button {
                                // Calculate price for custom amount
                                if let amount = Int(customTokenAmount), amount > 0 {
                                    let price = Double(amount) * 0.01 // ~$0.01 per token
                                    errorMessage = "Custom purchase: \(amount) tokens for $\(String(format: "%.2f", price)). Coming soon via App Store."
                                }
                            } label: {
                                Text("Buy")
                                    .font(.custom("Aptos-Bold", size: 16))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Theme.Colors.primaryFallback)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        Text("$0.01 per token for custom amounts")
                            .font(.custom("Aptos", size: 12))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    if let error = errorMessage {
                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    if let amount = purchasedAmount {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "#34A853"))
                            Text("Successfully added \(amount) tokens!")
                                .font(.custom("Aptos-Bold", size: 16))
                                .foregroundStyle(Color(hex: "#34A853"))
                        }
                        .padding()
                    }

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Token Store")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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

    // MARK: - Token Pack Row

    @ViewBuilder
    private func tokenPackRow(product: Product) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName)
                    .font(.custom("Aptos-Bold", size: 17))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(product.description)
                    .font(.custom("Aptos", size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Text(product.displayPrice)
                .font(.custom("Aptos-Bold", size: 18))
                .foregroundStyle(Theme.Colors.primaryFallback)
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(Theme.Colors.primaryFallback.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func placeholderTokenPack(name: String, description: String, price: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("Aptos-Bold", size: 17))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(description)
                    .font(.custom("Aptos", size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Text(price)
                .font(.custom("Aptos-Bold", size: 18))
                .foregroundStyle(Theme.Colors.primaryFallback)
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(Theme.Colors.primaryFallback.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func tokenCostRow(_ feature: String, cost: Int) -> some View {
        HStack {
            Text(feature)
                .font(.custom("Aptos", size: 15))
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            Text("\(cost) tokens")
                .font(.custom("Aptos-Bold", size: 15))
                .foregroundStyle(Theme.Colors.primaryFallback)
        }
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        do {
            let transaction = try await subscriptionService.purchase(product)
            if let transaction {
                let amount: Int
                switch product.id {
                case Constants.Products.tokenPack100: amount = 100
                case Constants.Products.tokenPack500: amount = 500
                case Constants.Products.tokenPack1000: amount = 1000
                case Constants.Products.tokenPack2500: amount = 2500
                default: amount = 0
                }

                if amount > 0 {
                    let tokenService = TokenService()
                    try await tokenService.addTokens(
                        amount: amount,
                        reason: "Token purchase: \(product.displayName)",
                        referenceId: String(transaction.id)
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
