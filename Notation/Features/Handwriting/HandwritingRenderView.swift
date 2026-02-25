import SwiftUI

struct HandwritingRenderView: View {
    let blocks: [TextBlock]
    /// When true, triggers a new render. The parent sets this; we reset it after rendering.
    @Binding var shouldConvert: Bool
    @State private var renderedImage: Image?
    @State private var missingChars: [Character] = []
    @State private var showMissingAlert = false
    @State private var isConverting = false

    var body: some View {
        ZStack {
            if let image = renderedImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            if isConverting {
                ProgressView("Converting...")
                    .font(.custom("Aptos", size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .allowsHitTesting(false)
        #if os(iOS)
        .onChange(of: shouldConvert) { _, newValue in
            if newValue {
                Task {
                    await renderHandwriting()
                    shouldConvert = false
                }
            }
        }
        .alert("Missing Characters", isPresented: $showMissingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The following characters haven't been drawn yet: \(missingChars.map { String($0) }.joined(separator: ", ")). They are shown in red.")
        }
        #endif
    }

    #if os(iOS)
    private func renderHandwriting() async {
        let text = blocks.map(\.text).joined(separator: "\n")
        guard !text.isEmpty else {
            renderedImage = nil
            return
        }

        isConverting = true
        defer { isConverting = false }

        let converter = HandwritingConverter()
        do {
            let result = try await converter.convertText(text, maxWidth: 515)
            withAnimation(Theme.Animation.standard) {
                renderedImage = Image(uiImage: result.image)
            }

            if !result.missingCharacters.isEmpty {
                missingChars = result.missingCharacters
                showMissingAlert = true
            }
        } catch {
            print("[HandwritingRender] Failed: \(error.localizedDescription)")
            renderedImage = nil
        }
    }
    #endif
}
