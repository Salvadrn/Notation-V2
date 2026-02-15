#if os(iOS)
import SwiftUI
import PencilKit
import UIKit

@MainActor
final class HandwritingConverter {
    private let glyphService: GlyphService

    init(glyphService: GlyphService = GlyphService()) {
        self.glyphService = glyphService
    }

    struct ConversionResult {
        let image: UIImage
        let missingCharacters: [Character]
    }

    /// Converts a string of text into a rendered handwriting image using the user's custom glyphs
    func convertText(_ text: String, maxWidth: CGFloat) async throws -> ConversionResult {
        let glyphs = glyphService.cachedGlyphs
        var missingCharacters: [Character] = []

        let charSize = Constants.Handwriting.baseCharacterSize
        let letterSpacing = Constants.Handwriting.letterSpacing
        let wordSpacing = Constants.Handwriting.wordSpacing
        let lineHeight = Constants.Handwriting.lineHeight

        // Calculate layout
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxX: CGFloat = 0

        struct GlyphPlacement {
            let character: Character
            let glyph: Glyph?
            let x: CGFloat
            let y: CGFloat
            let isMissing: Bool
        }

        var placements: [GlyphPlacement] = []

        for char in text {
            if char == "\n" {
                currentX = 0
                currentY += lineHeight
                continue
            }

            if char == " " {
                currentX += wordSpacing
                continue
            }

            let charString = String(char)
            let selectedGlyph = glyphs[charString]?.randomElement()
            let isMissing = selectedGlyph == nil && char != " "

            if isMissing && !missingCharacters.contains(char) {
                missingCharacters.append(char)
            }

            // Word wrap
            if currentX + charSize.width > maxWidth {
                currentX = 0
                currentY += lineHeight
            }

            placements.append(GlyphPlacement(
                character: char,
                glyph: selectedGlyph,
                x: currentX,
                y: currentY,
                isMissing: isMissing
            ))

            currentX += charSize.width + letterSpacing
            maxX = max(maxX, currentX)
        }

        let totalHeight = currentY + lineHeight
        let totalWidth = max(maxX, 1)

        // Render
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        let image = renderer.image { context in
            for placement in placements {
                let rect = CGRect(
                    x: placement.x,
                    y: placement.y,
                    width: charSize.width,
                    height: charSize.height
                )

                if let glyph = placement.glyph,
                   let drawing = try? PKDrawing(data: glyph.strokeData) {
                    let glyphImage = drawing.image(from: drawing.bounds, scale: 2.0)
                    glyphImage.draw(in: rect)
                } else if placement.isMissing {
                    // Draw missing character in red
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: charSize.height * 0.7),
                        .foregroundColor: UIColor.red
                    ]
                    let charString = String(placement.character) as NSString
                    charString.draw(in: rect, withAttributes: attributes)
                }
            }
        }

        return ConversionResult(image: image, missingCharacters: missingCharacters)
    }
}
#endif
