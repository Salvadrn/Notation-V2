import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
final class PDFExporter {

    // Export a single page to PDF data
    func exportPage(_ page: Page, textContent: NSAttributedString?) -> Data {
        let pageSize = page.displaySize
        let renderer = createPDFRenderer(size: pageSize)

        return renderer.pdfData { context in
            context.beginPage()
            drawPageContent(
                in: context.cgContext,
                page: page,
                textContent: textContent,
                size: pageSize
            )
        }
    }

    // Export multiple pages (entire notebook/section) to PDF data
    func exportPages(_ pages: [Page], textContents: [UUID: NSAttributedString]) -> Data {
        guard let firstPage = pages.first else {
            return Data()
        }

        let pageSize = firstPage.displaySize
        let renderer = createPDFRenderer(size: pageSize)

        return renderer.pdfData { context in
            for page in pages {
                let size = page.displaySize
                var pageRect = CGRect(origin: .zero, size: size)
                context.beginPage(withBounds: pageRect, pageInfo: [:])
                drawPageContent(
                    in: context.cgContext,
                    page: page,
                    textContent: textContents[page.id],
                    size: size
                )
            }
        }
    }

    // MARK: - Private

    private func createPDFRenderer(size: CGSize) -> UIGraphicsPDFRenderer {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Notation Export",
            kCGPDFContextCreator as String: "Notation App"
        ]
        return UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size), format: format)
    }

    private func drawPageContent(
        in context: CGContext,
        page: Page,
        textContent: NSAttributedString?,
        size: CGSize
    ) {
        // Draw white background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))

        // Draw ruled lines
        drawRuledLines(in: context, size: size)

        // Draw text content
        if let attributedString = textContent {
            let textRect = CGRect(
                x: 40,
                y: 40,
                width: size.width - 80,
                height: size.height - 80
            )
            attributedString.draw(in: textRect)
        } else {
            // Render from page.textContent blocks
            drawTextBlocks(page.textContent.blocks, in: context, size: size)
        }
    }

    private func drawRuledLines(in context: CGContext, size: CGSize) {
        let lineSpacing: CGFloat = 28
        let margin: CGFloat = 40
        let startY: CGFloat = 60

        context.setStrokeColor(CGColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1.0))
        context.setLineWidth(0.5)

        var y = startY
        while y < size.height - margin {
            context.move(to: CGPoint(x: margin, y: y))
            context.addLine(to: CGPoint(x: size.width - margin, y: y))
            y += lineSpacing
        }
        context.strokePath()
    }

    private func drawTextBlocks(_ blocks: [TextBlock], in context: CGContext, size: CGSize) {
        let margin: CGFloat = 40
        var yOffset: CGFloat = 50

        for block in blocks {
            let font: UIFont
            let color: UIColor

            switch block.style {
            case .heading:
                font = .systemFont(ofSize: 22, weight: .bold)
                color = .black
            case .subheading:
                font = .systemFont(ofSize: 18, weight: .semibold)
                color = .darkGray
            case .body:
                font = .systemFont(ofSize: 14, weight: .regular)
                color = .black
            case .bullet:
                font = .systemFont(ofSize: 14, weight: .regular)
                color = .black
            case .numbered:
                font = .systemFont(ofSize: 14, weight: .regular)
                color = .black
            case .quote:
                font = .italicSystemFont(ofSize: 14)
                color = .gray
            case .code:
                font = UIFont(name: "Menlo", size: 12) ?? .systemFont(ofSize: 12)
                color = .darkGray
            }

            let prefix: String
            switch block.style {
            case .bullet: prefix = "  \u{2022}  "
            case .quote: prefix = "  \u{201C} "
            default: prefix = ""
            }

            let text = prefix + block.text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]

            let maxWidth = size.width - (margin * 2)
            let textRect = CGRect(x: margin, y: yOffset, width: maxWidth, height: size.height - yOffset - margin)
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let boundingRect = attributedString.boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                context: nil
            )

            attributedString.draw(in: textRect)
            yOffset += boundingRect.height + 8

            if yOffset > size.height - margin {
                break
            }
        }
    }
}
