import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                SwiftUI.Section {
                    ProfileView(viewModel: viewModel)
                } header: {
                    Text("Profile")
                }

                // Subscription
                SwiftUI.Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Plan")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Text(viewModel.profile.isPro ? "Pro" : "Free")
                                .font(Theme.Typography.headline)
                                .foregroundStyle(viewModel.profile.isPro ? Theme.Colors.accent : Theme.Colors.textPrimary)
                        }
                        Spacer()

                        if !viewModel.profile.isPro {
                            Button("Upgrade") {
                                viewModel.showSubscription = true
                            }
                            .font(Theme.Typography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.full))
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Token Balance")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Text("\(viewModel.tokenBalance) tokens")
                                .font(Theme.Typography.headline)
                                .foregroundStyle(Theme.Colors.primaryFallback)
                        }
                        Spacer()

                        Button("Buy Tokens") {
                            viewModel.showTokenStore = true
                        }
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                } header: {
                    Text("Subscription & Tokens")
                }

                // App Info
                SwiftUI.Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                } header: {
                    Text("About")
                }

                // Sign Out
                SwiftUI.Section {
                    Button(role: .destructive) {
                        Task { await viewModel.signOut() }
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $viewModel.showTokenStore) {
                TokenStoreView()
            }
            .onFirstAppear {
                await viewModel.loadProfile()
            }
            .withErrorHandling()
        }
    }
}
