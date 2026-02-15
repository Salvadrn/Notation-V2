import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#elseif os(macOS)
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#endif

@MainActor
final class PDFExporter {

    // Export a single page to PDF data
    func exportPage(_ page: Page, textContent: NSAttributedString?) -> Data {
        let pageSize = page.displaySize
        return createPDFData(size: pageSize) { context in
            drawPageContent(
                in: context,
                page: page,
                textContent: textContent,
                size: pageSize
            )
        }
    }

    // Export multiple pages (entire notebook/section) to PDF data
    func exportPages(_ pages: [Page], textContents: [UUID: NSAttributedString]) -> Data {
        guard !pages.isEmpty else {
            return Data()
        }

        let mutableData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutableData as CFMutableData),
              let firstPage = pages.first else {
            return Data()
        }

        let firstSize = firstPage.displaySize
        var mediaBox = CGRect(origin: .zero, size: firstSize)

        guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        let info: [CFString: CFString] = [
            kCGPDFContextTitle: "Notation Export" as CFString,
            kCGPDFContextCreator: "Notation App" as CFString
        ]

        for page in pages {
            let size = page.displaySize
            var pageRect = CGRect(origin: .zero, size: size)
            pdfContext.beginPDFPage(info as CFDictionary)
            drawPageContent(
                in: pdfContext,
                page: page,
                textContent: textContents[page.id],
                size: size
            )
            pdfContext.endPDFPage()
        }

        pdfContext.closePDF()
        return mutableData as Data
    }

    // MARK: - Private

    private func createPDFData(size: CGSize, draw: (CGContext) -> Void) -> Data {
        #if os(iOS)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Notation Export",
            kCGPDFContextCreator as String: "Notation App"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size), format: format)
        return renderer.pdfData { context in
            context.beginPage()
            draw(context.cgContext)
        }
        #elseif os(macOS)
        let mutableData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: size)
        guard let consumer = CGDataConsumer(data: mutableData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }
        let info: [CFString: CFString] = [
            kCGPDFContextTitle: "Notation Export" as CFString,
            kCGPDFContextCreator: "Notation App" as CFString
        ]
        pdfContext.beginPDFPage(info as CFDictionary)
        draw(pdfContext)
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        return mutableData as Data
        #endif
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
            let font: PlatformFont
            let color: PlatformColor

            switch block.style {
            case .heading:
                font = .systemFont(ofSize: 22, weight: .bold)
                color = PlatformColor.black
            case .subheading:
                font = .systemFont(ofSize: 18, weight: .semibold)
                color = PlatformColor.darkGray
            case .body:
                font = .systemFont(ofSize: 14, weight: .regular)
                color = PlatformColor.black
            case .bullet:
                font = .systemFont(ofSize: 14, weight: .regular)
                color = PlatformColor.black
            case .numbered:
                font = .systemFont(ofSize: 14, weight: .regular)
                color = PlatformColor.black
            case .quote:
                #if os(iOS)
                font = PlatformFont.italicSystemFont(ofSize: 14)
                #else
                font = NSFontManager.shared.convert(.systemFont(ofSize: 14), toHaveTrait: .italicFontMask)
                #endif
                color = PlatformColor.gray
            case .code:
                font = PlatformFont(name: "Menlo", size: 12) ?? .systemFont(ofSize: 12)
                color = PlatformColor.darkGray
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
