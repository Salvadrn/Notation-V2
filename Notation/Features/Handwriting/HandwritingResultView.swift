#if os(iOS)
import SwiftUI
import UIKit

enum HandwritingAction {
    case insertNewPage
    case replaceInCurrentPage
    case insertInCurrentPage
}

struct HandwritingResultView: View {
    let textBlocks: [TextBlock]
    var onAction: ((HandwritingAction, UIImage) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?
    @State private var missingChars: [Character] = []
    @State private var isConverting = true

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                if isConverting {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.3)
                        Text("Converting to your handwriting...")
                            .font(.custom("Aptos", size: 15))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                } else if let image = renderedImage {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Small preview
                            VStack(spacing: 12) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .softShadow()

                                Text("Preview")
                                    .font(.custom("Aptos", size: 12))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            .padding(.top, 8)

                            if !missingChars.isEmpty {
                                missingCharsBanner
                            }

                            // Action options
                            VStack(spacing: 14) {
                                Text("What would you like to do?")
                                    .font(.custom("Aptos-Bold", size: 18))
                                    .foregroundStyle(Theme.Colors.textPrimary)

                                actionButton(
                                    icon: "doc.badge.plus",
                                    title: "Insert into New Page",
                                    subtitle: "Creates a new page with your handwriting",
                                    action: .insertNewPage
                                )

                                actionButton(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Replace in Current Page",
                                    subtitle: "Replaces typed text with handwritten version",
                                    action: .replaceInCurrentPage
                                )

                                actionButton(
                                    icon: "plus.rectangle.on.rectangle",
                                    title: "Insert into Current Page",
                                    subtitle: "Adds handwriting below existing content",
                                    action: .insertInCurrentPage
                                )
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Text("Could not convert text")
                            .font(.custom("Aptos-Bold", size: 17))
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Text("Make sure you have drawn characters in Alphabet Studio.")
                            .font(.custom("Aptos", size: 14))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                    }
                }
            }
            .navigationTitle("Handwriting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            await convertText()
        }
    }

    // MARK: - Action Button

    private func actionButton(icon: String, title: String, subtitle: String, action: HandwritingAction) -> some View {
        Button {
            HapticService.medium()
            guard let image = renderedImage else { return }
            onAction?(action, image)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: "#1B2A4A"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#1B2A4A").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.custom("Aptos-Bold", size: 16))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(subtitle)
                        .font(.custom("Aptos", size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(16)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
    }

    // MARK: - Missing Characters Banner

    private var missingCharsBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Missing characters (shown in red)")
                    .font(.custom("Aptos-Bold", size: 12))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(missingChars.map { String($0) }.joined(separator: "  "))
                    .font(.custom("Aptos", size: 13))
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(14)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Conversion

    private func convertText() async {
        let text = textBlocks.map(\.text).joined(separator: "\n")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isConverting = false
            return
        }

        let converter = HandwritingConverter()
        do {
            let result = try await converter.convertText(text, maxWidth: 515)
            withAnimation {
                renderedImage = result.image
                missingChars = result.missingCharacters
            }
        } catch {
            print("[HandwritingResult] Failed: \(error.localizedDescription)")
        }
        isConverting = false
    }
}
#endif
