import SwiftUI

struct HandwritingRenderView: View {
    let blocks: [TextBlock]
    @State private var renderedImage: Image?
    @State private var missingChars: [Character] = []
    @State private var showMissingAlert = false

    var body: some View {
        ZStack {
            if let image = renderedImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .allowsHitTesting(false)
        #if os(iOS)
        .task(id: blocks.map(\.text).joined()) {
            await renderHandwriting()
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

        let converter = HandwritingConverter()
        do {
            let result = try await converter.convertText(text, maxWidth: 515) // A4 width - margins
            renderedImage = Image(uiImage: result.image)

            if !result.missingCharacters.isEmpty {
                missingChars = result.missingCharacters
                showMissingAlert = true
            }
        } catch {
            // Silently fail for rendering
        }
    }
    #endif
}
