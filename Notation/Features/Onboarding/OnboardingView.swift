import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var animateContent = false

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "book.closed.fill",
            title: "Create Notebooks",
            description: "Organize your notes into notebooks and sections. Use folders to keep everything tidy.",
            tip: "Tap + in the sidebar to create a new notebook or folder."
        ),
        OnboardingStep(
            icon: "pencil.and.scribble",
            title: "Write & Draw",
            description: "Type notes directly on any page. On iPad, use Apple Pencil to draw and sketch.",
            tip: "Swipe left and right to navigate between pages."
        ),
        OnboardingStep(
            icon: "hand.draw.fill",
            title: "Your Handwriting",
            description: "Draw your alphabet in the Alphabet Studio. Then convert any typed text into your own handwriting.",
            tip: "Find Alphabet Studio in the sidebar under Quick Actions."
        ),
        OnboardingStep(
            icon: "sparkles",
            title: "AI-Powered Notes",
            description: "Upload a photo of slides, textbooks, or notes and let AI generate structured study notes instantly.",
            tip: "Try Generate AI Notes from the Quick Actions menu."
        ),
        OnboardingStep(
            icon: "star.fill",
            title: "Stay Organized",
            description: "Mark notebooks as favorites for quick access. Deleted items stay in trash for 30 days.",
            tip: "Long-press any notebook to see all available actions."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Skip")
                        .font(.custom("Aptos", size: 15))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Content
            if currentStep < steps.count {
                let step = steps[currentStep]

                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primaryFallback.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: step.icon)
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .opacity(animateContent ? 1 : 0)

                    // Text
                    VStack(spacing: 14) {
                        Text(step.title)
                            .font(.custom("Aptos-Bold", size: 28))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text(step.description)
                            .font(.custom("Aptos", size: 16))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 16)

                    // Tip box
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow)
                        Text(step.tip)
                            .font(.custom("Aptos", size: 14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(16)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: 340)
                    .opacity(animateContent ? 1 : 0)
                }
                .animation(.easeOut(duration: 0.5), value: animateContent)
            }

            Spacer()

            // Bottom controls
            VStack(spacing: 20) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(currentStep == index
                                ? Theme.Colors.primaryFallback
                                : Theme.Colors.backgroundTertiary
                            )
                            .frame(
                                width: currentStep == index ? 24 : 8,
                                height: 8
                            )
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentStep)
                    }
                }

                // Action button
                Button {
                    #if os(iOS)
                    HapticService.light()
                    #endif
                    if currentStep < steps.count - 1 {
                        animateContent = false
                        withAnimation(.easeOut(duration: 0.15)) {
                            currentStep += 1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { animateContent = true }
                        }
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(currentStep < steps.count - 1 ? "Next" : "Get Started")
                        .font(.custom("Aptos-Bold", size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.primaryFallback)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 28)
            }
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

private struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
    let tip: String
}
