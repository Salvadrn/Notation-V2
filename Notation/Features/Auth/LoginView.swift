import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject var supabase: SupabaseService
    @State private var showEmailSignIn = false
    @State private var currentPage = 0
    @State private var animateLogo = false
    @State private var animateContent = false

    private let featurePages: [FeaturePage] = [
        FeaturePage(
            icon: "pencil.and.scribble",
            title: "Write & Draw Freely",
            description: "Type notes or sketch with Apple Pencil. Your pages, your way."
        ),
        FeaturePage(
            icon: "hand.draw.fill",
            title: "Your Handwriting, Digitized",
            description: "Draw your alphabet once. Convert any typed text into your own handwriting."
        ),
        FeaturePage(
            icon: "sparkles",
            title: "AI-Powered Notes",
            description: "Upload a slide or photo and let AI generate structured study notes instantly."
        ),
        FeaturePage(
            icon: "icloud.fill",
            title: "Sync Everywhere",
            description: "Sign in to sync notebooks across iPhone, iPad, and Mac seamlessly."
        )
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#0C0C0E")
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: geo.size.height * 0.07)

                        // MARK: — Logo + Title
                        logoSection
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 16)

                        Spacer(minLength: 40)

                        // MARK: — Feature Carousel
                        featureCarousel(geo: geo)
                            .opacity(animateContent ? 1 : 0)

                        Spacer(minLength: 40)

                        // MARK: — Action Buttons
                        actionButtons
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)

                        Spacer(minLength: geo.size.height * 0.05)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInSheet()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                animateLogo = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.25)) {
                animateContent = true
            }
            startAutoScroll()
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 22) {
            // App icon — bigger
            RoundedRectangle(cornerRadius: 34)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1C1C24"), Color(hex: "#14141A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 34)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .overlay(
                    Text("N")
                        .font(.custom("Aptos-Bold", size: 60))
                        .foregroundStyle(.white)
                )
                .scaleEffect(animateLogo ? 1 : 0.8)
                .opacity(animateLogo ? 1 : 0)

            VStack(spacing: 10) {
                Text("Notation")
                    .font(.custom("Aptos-Bold", size: 46))
                    .foregroundStyle(.white)

                Text("Write it. Draw it. Own it.")
                    .font(.custom("Aptos-Bold", size: 18))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Feature Carousel

    private func featureCarousel(geo: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            TabView(selection: $currentPage) {
                ForEach(Array(featurePages.enumerated()), id: \.offset) { index, page in
                    featureSlide(page, geo: geo)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: geo.size.height * 0.30)

            // Page dots — capsule style
            HStack(spacing: 8) {
                ForEach(0..<featurePages.count, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.2))
                        .frame(
                            width: currentPage == index ? 24 : 6,
                            height: 6
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                }
            }
        }
    }

    private func featureSlide(_ page: FeaturePage, geo: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            // Feature icon area
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.04))
                    .frame(maxWidth: geo.size.width * 0.65, maxHeight: 140)

                VStack(spacing: 14) {
                    Image(systemName: page.icon)
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))

                    // Mockup lines
                    VStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: [130, 100, 70][i], height: 2)
                        }
                    }
                }
            }

            // Text — all bold
            VStack(spacing: 10) {
                Text(page.title)
                    .font(.custom("Aptos-Bold", size: 26))
                    .foregroundStyle(.white)

                Text(page.description)
                    .font(.custom("Aptos-Bold", size: 16))
                    .foregroundStyle(.white.opacity(0.40))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 310)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.custom("Aptos-Bold", size: 14))
                    .foregroundStyle(Color(hex: "#CC4444"))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
            }

            // Primary CTA — Start Writing (Guest)
            Button {
                supabase.enterGuestMode()
            } label: {
                Text("Start Writing")
                    .font(.custom("Aptos-Bold", size: 20))
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Apple Sign In
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Email Sign In
            Button {
                showEmailSignIn = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                    Text("Sign in with Email")
                        .font(.custom("Aptos-Bold", size: 18))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .foregroundStyle(.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 4)
            }

            Text("No account needed to start. Sign in later for cloud sync.")
                .font(.custom("Aptos-Bold", size: 12))
                .foregroundStyle(.white.opacity(0.18))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Auto Scroll

    private func startAutoScroll() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage = (currentPage + 1) % featurePages.count
            }
        }
    }

    // MARK: - Handlers

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await viewModel.signInWithApple(credential: credential)
                    if supabase.isAuthenticated { supabase.completeOnboarding() }
                }
            }
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Feature Page Model

private struct FeaturePage {
    let icon: String
    let title: String
    let description: String
}
