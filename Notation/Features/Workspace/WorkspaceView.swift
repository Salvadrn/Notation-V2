import SwiftUI
import AuthenticationServices

struct WorkspaceView: View {
    @StateObject private var viewModel = WorkspaceViewModel()
    @EnvironmentObject var supabase: SupabaseService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showSettings = false
    @State private var showSignIn = false
    @State private var showProBanner = false
    @State private var showOnboarding = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    private static let onboardingShownKey = "notation_has_shown_onboarding"

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
                .navigationTitle("Notation")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                #if os(iOS)
                                HapticService.light()
                                #endif
                                viewModel.showNewFolder = true
                            } label: {
                                Label("New Folder", systemImage: "folder.badge.plus")
                            }

                            Button {
                                #if os(iOS)
                                HapticService.light()
                                #endif
                                viewModel.showNewNotebook = true
                            } label: {
                                Label("New Notebook", systemImage: "book.closed.fill")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }

                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            #if os(iOS)
                            HapticService.light()
                            #endif
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if supabase.isGuestMode {
                        guestBanner
                    }
                }
        } detail: {
            if let notebook = viewModel.selectedNotebook {
                NotebookView(notebook: notebook)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            backToNotebooksButton
                        }
                    }
            } else if let quickAction = viewModel.selectedQuickAction {
                quickActionDetail(quickAction)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            backToNotebooksButton
                        }
                    }
            } else {
                VStack(spacing: 0) {
                    // Sync status bar
                    syncStatusBar

                    if supabase.isGuestMode {
                        guestInfoBar
                    }

                    if viewModel.activeFilter != .trash {
                        BreadcrumbView(folders: viewModel.breadcrumb) { folder in
                            Task { await viewModel.selectFolder(folder) }
                        }
                    }

                    if viewModel.activeFilter == .trash {
                        // Trash header with empty trash button
                        if viewModel.trashCount > 0 {
                            HStack {
                                Text("\(viewModel.trashCount) items in trash")
                                    .font(.custom("Aptos", size: 13))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                Spacer()
                                Button(role: .destructive) {
                                    Task { await viewModel.emptyTrash() }
                                } label: {
                                    Text("Empty Trash")
                                        .font(.custom("Aptos-Bold", size: 13))
                                        .foregroundStyle(Theme.Colors.destructive)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, 8)
                            .background(Theme.Colors.destructive.opacity(0.06))
                        }
                    }

                    if viewModel.filteredNotebooks.isEmpty && !viewModel.isLoading {
                        if viewModel.activeFilter == .favorites {
                            EmptyStateView(
                                icon: "star",
                                title: "No Favorites",
                                subtitle: "Long-press a notebook and tap the star to add it to favorites"
                            )
                        } else if viewModel.activeFilter == .trash {
                            EmptyStateView(
                                icon: "trash",
                                title: "Trash is Empty",
                                subtitle: "Deleted notebooks will appear here for 30 days"
                            )
                        } else {
                            welcomeView
                        }
                    } else {
                        NotebookGridView(
                            notebooks: viewModel.filteredNotebooks,
                            isTrashMode: viewModel.activeFilter == .trash,
                            onSelect: { notebook in
                                guard !notebook.isDeleted else { return }
                                viewModel.selectedQuickAction = nil
                                viewModel.selectedNotebook = notebook
                                withAnimation {
                                    columnVisibility = .detailOnly
                                }
                            },
                            onDelete: { notebook in
                                if viewModel.activeFilter == .trash {
                                    Task { await viewModel.permanentlyDeleteNotebook(notebook) }
                                } else {
                                    Task { await viewModel.softDeleteNotebook(notebook) }
                                }
                            },
                            onRename: { notebook, name in
                                Task { await viewModel.renameNotebook(notebook, to: name) }
                            },
                            onToggleFavorite: { notebook in
                                Task { await viewModel.toggleFavorite(notebook) }
                            },
                            onRestore: { notebook in
                                Task { await viewModel.restoreNotebook(notebook) }
                            }
                        )
                    }
                }
                .searchable(text: $viewModel.searchText, prompt: "Search notebooks...")
                .navigationTitle(detailNavigationTitle)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            }
        }
        .sheet(isPresented: $viewModel.showNewFolder) {
            NewFolderSheet { name in
                Task { await viewModel.createFolder(name: name) }
            }
        }
        .sheet(isPresented: $viewModel.showNewNotebook) {
            NewNotebookSheet { title in
                Task { await viewModel.createNotebook(title: title) }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showSignIn) {
            SignInSheet()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onFirstAppear {
            viewModel.configure(subscriptionService: subscriptionService)
            await viewModel.loadWorkspace()
            // Show onboarding on first workspace visit
            if !UserDefaults.standard.bool(forKey: Self.onboardingShownKey) {
                UserDefaults.standard.set(true, forKey: Self.onboardingShownKey)
                showOnboarding = true
            }
        }
        .withErrorHandling()
        .overlay {
            // Pro upgrade banner for free/guest users
            if showProBanner && !subscriptionService.isProUser {
                proUpgradeBanner
            }
        }
        .task {
            // Show pro banner after delay, auto-cancelled when view disappears
            guard !subscriptionService.isProUser else { return }
            try? await Task.sleep(for: .seconds(Constants.PromoBanner.showEveryNMinutes))
            guard !Task.isCancelled else { return }
            withAnimation(Theme.Animation.smooth) {
                showProBanner = true
            }
        }
    }

    private func scheduleNextBanner() {
        Task {
            try? await Task.sleep(for: .seconds(Constants.PromoBanner.showEveryNMinutes))
            guard !Task.isCancelled else { return }
            withAnimation(Theme.Animation.smooth) {
                showProBanner = true
            }
        }
    }

    // MARK: - Computed Properties

    private var detailNavigationTitle: String {
        switch viewModel.activeFilter {
        case .favorites: return "Favorites"
        case .trash: return "Recently Deleted"
        case .all: return viewModel.selectedFolder?.name ?? "All Notebooks"
        }
    }

    // MARK: - Sync Status Bar

    @ViewBuilder
    private var syncStatusBar: some View {
        switch viewModel.syncStatus {
        case .syncing:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Syncing...")
                    .font(.custom("Aptos", size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(Theme.Colors.primaryFallback.opacity(0.08))
            .transition(.move(edge: .top).combined(with: .opacity))
        case .synced:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.icloud.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.success)
                Text("All changes saved")
                    .font(.custom("Aptos", size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(Theme.Colors.success.opacity(0.08))
            .transition(.move(edge: .top).combined(with: .opacity))
        case .error:
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.icloud.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.destructive)
                Text("Sync error — tap to retry")
                    .font(.custom("Aptos", size: 12))
                    .foregroundStyle(Theme.Colors.destructive)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(Theme.Colors.destructive.opacity(0.08))
            .onTapGesture {
                Task { await viewModel.loadWorkspace() }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        case .offline, .idle:
            EmptyView()
        }
    }

    // MARK: - Navigation Helpers

    private var backToNotebooksButton: some View {
        Button {
            viewModel.selectedNotebook = nil
            viewModel.selectedQuickAction = nil
            withAnimation {
                columnVisibility = .all
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Notebooks")
            }
            .font(.custom("Aptos", size: 16))
            .foregroundStyle(Theme.Colors.primaryFallback)
        }
    }

    @ViewBuilder
    private func quickActionDetail(_ action: QuickAction) -> some View {
        switch action {
        #if os(iOS)
        case .alphabetStudio:
            AlphabetStudioView()
        #endif
        case .aiNotes:
            AINotesView()
        }
    }

    // MARK: - Pro Upgrade Banner

    private var proUpgradeBanner: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showProBanner = false }
                }

            VStack(spacing: 24) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        withAnimation { showProBanner = false }
                        scheduleNextBanner()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 80, height: 80)
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Title
                VStack(spacing: 10) {
                    Text("Upgrade to Pro")
                        .font(.custom("Aptos-Bold", size: 26))
                        .foregroundStyle(.white)

                    if supabase.isGuestMode {
                        Text("You have \(viewModel.notebooks.count)/\(Constants.FreeTier.maxNotebooks) notebooks.\nUnlock unlimited notebooks, AI notes, cloud sync, and more.")
                            .font(.custom("Aptos", size: 15))
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Unlock unlimited notebooks, AI-powered notes, real-time collaboration, and cloud sync across devices.")
                            .font(.custom("Aptos", size: 15))
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                }

                // Features
                VStack(spacing: 12) {
                    bannerFeature(icon: "infinity", text: "Unlimited notebooks & pages")
                    bannerFeature(icon: "sparkles", text: "500 AI tokens/month included")
                    bannerFeature(icon: "icloud.fill", text: "Cloud sync across devices")
                    bannerFeature(icon: "person.2.fill", text: "Real-time collaboration")
                }
                .padding(18)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // CTA
                Button {
                    withAnimation { showProBanner = false }
                    showSettings = true
                } label: {
                    Text("View Plans — Starting at $4.99/mo")
                        .font(.custom("Aptos-Bold", size: 17))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button("Maybe Later") {
                    withAnimation { showProBanner = false }
                    scheduleNextBanner()
                }
                .font(.custom("Aptos", size: 14))
                .foregroundStyle(.white.opacity(0.4))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(hex: "#141414"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.6), radius: 30, y: 10)
            .padding(28)
        }
        .transition(.opacity)
    }

    private func bannerFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 26)
            Text(text)
                .font(.custom("Aptos", size: 15))
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
        }
    }

    // MARK: - Guest Banner (sidebar bottom)

    private var guestBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Guest Mode")
                        .font(.custom("Aptos-Bold", size: 12))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Data saved locally")
                        .font(.custom("Aptos", size: 10))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                Spacer()
            }

            // Sign-in button in sidebar
            Button {
                showSignIn = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 12))
                    Text("Sign In for Cloud Sync")
                        .font(.custom("Aptos-Bold", size: 11))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.Colors.primaryFallback)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.Colors.backgroundSecondary)
    }

    // MARK: - Guest info bar (detail top)

    private var guestInfoBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.accent)
            Text("Files are saved on this device only. \(viewModel.notebooks.count)/\(Constants.FreeTier.maxNotebooks) notebooks used.")
                .font(.custom("Aptos", size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Button("Sign In") {
                showSignIn = true
            }
            .font(.custom("Aptos-Bold", size: 12))
            .foregroundStyle(Theme.Colors.primaryFallback)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, 8)
        .background(Theme.Colors.accent.opacity(0.08))
    }

    // MARK: - Welcome view when no notebooks

    private var welcomeView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.Colors.primaryFallback)

                Text("Welcome to Notation")
                    .font(.custom("Aptos-Bold", size: 26))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Create a notebook to start writing, drawing, and organizing your ideas.")
                    .font(.custom("Aptos", size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            Button {
                viewModel.showNewNotebook = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Notebook")
                        .font(.custom("Aptos-Bold", size: 16))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Theme.Colors.primaryFallback)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Quick tips
            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "book.closed.fill", text: "Notebooks contain sections and pages")
                tipRow(icon: "folder.fill", text: "Organize notebooks into folders")
                tipRow(icon: "hand.draw.fill", text: "Draw with Apple Pencil on iPad")
                tipRow(icon: "keyboard", text: "Type directly on any page")
            }
            .padding(20)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: 360)

            // Sign-in prompt for guests in welcome view
            if supabase.isGuestMode {
                Button {
                    showSignIn = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("Sign in for cloud sync & Pro features")
                            .font(.custom("Aptos", size: 14))
                    }
                    .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.xl)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.primaryFallback)
                .frame(width: 24)
            Text(text)
                .font(.custom("Aptos", size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Sign-In Sheet (accessible from workspace)

struct SignInSheet: View {
    @EnvironmentObject var supabase: SupabaseService
    @Environment(\.dismiss) private var dismiss
    @State private var showEmailSignIn = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Colors.primaryFallback)

                    Text("Sign In to Notation")
                        .font(.custom("Aptos-Bold", size: 24))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Sync your notebooks across devices, collaborate in real-time, and unlock unlimited notebooks.")
                        .font(.custom("Aptos", size: 15))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }

                // Benefits
                VStack(alignment: .leading, spacing: 10) {
                    signInBenefit(icon: "icloud.fill", text: "Cloud sync across all devices")
                    signInBenefit(icon: "person.2.fill", text: "Real-time collaboration")
                    signInBenefit(icon: "infinity", text: "Unlimited notebooks & pages")
                    signInBenefit(icon: "sparkles", text: "AI-powered note generation")
                }
                .padding(20)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Spacer()

                // Sign In buttons
                VStack(spacing: 14) {
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Email Sign In
                    Button {
                        showEmailSignIn = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 20))
                            Text("Sign in with Email")
                                .font(.custom("Aptos-Bold", size: 17))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }

                    Text("Your local notebooks will remain on this device.")
                        .font(.custom("Aptos", size: 12))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .navigationTitle("Sign In")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .withErrorHandling()
            .sheet(isPresented: $showEmailSignIn) {
                EmailSignInSheet()
            }
        }
    }

    private func signInBenefit(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.primaryFallback)
                .frame(width: 28)
            Text(text)
                .font(.custom("Aptos", size: 15))
                .foregroundStyle(Theme.Colors.textPrimary)
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
                        supabase.exitGuestMode()
                        let authService = AuthService()
                        try await authService.signInWithApple(
                            idToken: idToken,
                            fullName: credential.fullName
                        )
                        await supabase.restoreSession()
                        supabase.observeAuthChanges()
                        dismiss()
                    } catch {
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
