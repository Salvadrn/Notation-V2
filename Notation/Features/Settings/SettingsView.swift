import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var appearance = AppearanceManager.shared
    @EnvironmentObject var supabase: SupabaseService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var showEmailSignIn = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                if supabase.isGuestMode {
                    guestAccountSection
                } else {
                    // Profile Section for signed-in users
                    SwiftUI.Section {
                        ProfileView(viewModel: viewModel)
                    } header: {
                        Text("Profile")
                    }

                    // Subscription (only for signed-in users)
                    SwiftUI.Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current Plan")
                                    .font(Theme.Typography.subheadline)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                Text(subscriptionService.isProUser ? "Pro" : "Free")
                                    .font(Theme.Typography.headline)
                                    .foregroundStyle(subscriptionService.isProUser ? Theme.Colors.accent : Theme.Colors.textPrimary)
                            }
                            Spacer()

                            if !subscriptionService.isProUser {
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
                }

                // Appearance Section
                SwiftUI.Section {
                    HStack(spacing: 12) {
                        Image(systemName: appearance.currentMode.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.primaryFallback)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appearance")
                                .font(.custom("Aptos-Bold", size: 15))
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text(appearance.currentMode.rawValue)
                                .font(.custom("Aptos", size: 12))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }

                        Spacer()

                        Picker("", selection: $appearance.currentMode) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.Colors.primaryFallback)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: appearance.pageSwipeDirection.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.primaryFallback)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Page Swipe")
                                .font(.custom("Aptos-Bold", size: 15))
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text(appearance.pageSwipeDirection.rawValue)
                                .font(.custom("Aptos", size: 12))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }

                        Spacer()

                        Picker("", selection: $appearance.pageSwipeDirection) {
                            ForEach(PageSwipeDirection.allCases, id: \.self) { dir in
                                Label(dir.rawValue, systemImage: dir.icon)
                                    .tag(dir)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.Colors.primaryFallback)
                    }
                } header: {
                    Text("Appearance")
                }

                // Debug (only in dev builds)
                #if DEBUG
                SwiftUI.Section {
                    Toggle(isOn: Binding(
                        get: { subscriptionService.debugProOverride },
                        set: { _ in subscriptionService.toggleDebugPro() }
                    )) {
                        HStack(spacing: 10) {
                            Image(systemName: "hammer.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Debug Pro Mode")
                                    .font(.custom("Aptos-Bold", size: 15))
                                Text(subscriptionService.debugProOverride ? "Pro active (test)" : "Off")
                                    .font(.custom("Aptos", size: 12))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                        }
                    }
                    .tint(.orange)
                } header: {
                    Text("Developer")
                } footer: {
                    Text("This section only appears in debug builds. It will not be visible in the App Store version.")
                }
                #endif

                // App Info
                SwiftUI.Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                } header: {
                    Text("About")
                }

                // Sign Out / Exit Guest
                SwiftUI.Section {
                    Button(role: .destructive) {
                        #if os(iOS)
                        HapticService.medium()
                        #endif
                        Task { await viewModel.signOut() }
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text(supabase.isGuestMode ? "Exit Guest Mode" : "Sign Out")
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
            .sheet(isPresented: $showEmailSignIn) {
                EmailSignInSheet()
            }
            .onFirstAppear {
                await viewModel.loadProfile()
            }
            .withErrorHandling()
        }
    }

    // MARK: - Guest Account Section with Sign-In Options

    private var guestAccountSection: some View {
        SwiftUI.Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.backgroundSecondary)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Guest Mode")
                            .font(.custom("Aptos-Bold", size: 17))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("Data saved locally on this device")
                            .font(.custom("Aptos", size: 13))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .padding(.vertical, 4)

            // Upgrade prompt
            VStack(alignment: .leading, spacing: 8) {
                Text("Sign in to unlock Pro features:")
                    .font(.custom("Aptos-Bold", size: 14))
                    .foregroundStyle(Theme.Colors.textPrimary)

                VStack(alignment: .leading, spacing: 6) {
                    upgradeFeatureRow(icon: "icloud.fill", text: "Cloud sync across devices")
                    upgradeFeatureRow(icon: "person.2.fill", text: "Real-time collaboration")
                    upgradeFeatureRow(icon: "infinity", text: "Unlimited notebooks")
                    upgradeFeatureRow(icon: "sparkles", text: "AI-powered notes")
                }
            }
            .padding(.vertical, 4)

            // Apple Sign In button
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Email Sign In button
            Button {
                showEmailSignIn = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 20))
                    Text("Sign in with Email")
                        .font(.custom("Aptos-Bold", size: 16))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        } header: {
            Text("Account")
        }
    }

    private func upgradeFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 20)
            Text(text)
                .font(.custom("Aptos", size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let tokenData = credential.identityToken,
               let idToken = String(data: tokenData, encoding: .utf8) {
                Task {
                    do {
                        // Exit guest mode first
                        supabase.exitGuestMode()
                        let authService = AuthService()
                        try await authService.signInWithApple(
                            idToken: idToken,
                            fullName: credential.fullName
                        )
                        // Restore session so isAuthenticated updates
                        await supabase.restoreSession()
                        supabase.observeAuthChanges()
                        dismiss()
                    } catch {
                        // If sign-in fails, re-enter guest mode
                        supabase.enterGuestMode()
                        ErrorHandler.shared.handle(error, title: "Sign In Failed")
                    }
                }
            }
        case .failure(let error):
            ErrorHandler.shared.handle(error, title: "Apple Sign In Failed")
        }
    }

}
