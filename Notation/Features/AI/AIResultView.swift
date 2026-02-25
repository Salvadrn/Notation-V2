import SwiftUI
import Translation

struct AIResultView: View {
    let notes: AIGeneratedNotes
    @State private var copied = false
    @State private var translatedNotes: AIGeneratedNotes?
    @State private var isTranslated = false
    @State private var showTranslationConfig = false

    /// The notes to display (translated or original)
    private var displayNotes: AIGeneratedNotes {
        isTranslated ? (translatedNotes ?? notes) : notes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Title
            Text(displayNotes.title)
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)

            // Summary
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Summary", systemImage: "doc.text")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryFallback)

                Text(displayNotes.summary)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.primaryFallback.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))

            // Sections
            ForEach(displayNotes.sections) { section in
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(section.heading)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    ForEach(section.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Text("\u{2022}")
                                .foregroundStyle(Theme.Colors.primaryFallback)
                            Text(bullet)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            }

            // Key Definitions
            if !displayNotes.keyDefinitions.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Label("Key Definitions", systemImage: "bookmark.fill")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.accent)

                    ForEach(displayNotes.keyDefinitions) { definition in
                        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                            Text(definition.term)
                                .font(Theme.Typography.headline)
                                .foregroundStyle(Theme.Colors.textPrimary)

                            Text(definition.definition)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.accent.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            }

            // Action buttons
            HStack(spacing: 12) {
                // Translate button
                if #available(iOS 17.4, macOS 14.4, *) {
                    Button {
                        if isTranslated {
                            withAnimation { isTranslated = false }
                        } else {
                            showTranslationConfig = true
                        }
                    } label: {
                        Label(
                            isTranslated ? "Original" : "Translate",
                            systemImage: isTranslated ? "arrow.uturn.backward" : "translate"
                        )
                            .font(Theme.Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.backgroundTertiary)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }
                }

                // Copy button
                Button {
                    let text = formatNotesAsText(displayNotes)
                    #if os(iOS)
                    UIPasteboard.general.string = text
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    #endif
                    withAnimation { copied = true }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation { copied = false }
                    }
                } label: {
                    Label(
                        copied ? "Copied!" : "Copy",
                        systemImage: copied ? "checkmark.circle.fill" : "doc.on.clipboard"
                    )
                        .font(Theme.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(copied ? Color(hex: "#34A853") : Theme.Colors.primaryFallback)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                }
            }
        }
        .modifier(TranslationModifier(
            isPresented: $showTranslationConfig,
            text: formatNotesAsText(notes),
            onTranslation: { translated in
                translatedNotes = parseTranslatedText(translated)
                withAnimation { isTranslated = true }
            }
        ))
    }

    private func formatNotesAsText(_ source: AIGeneratedNotes) -> String {
        var lines: [String] = []
        lines.append("# \(source.title)")
        lines.append("")
        lines.append(source.summary)
        lines.append("")
        for section in source.sections {
            lines.append("## \(section.heading)")
            for bullet in section.bullets {
                lines.append("- \(bullet)")
            }
            lines.append("")
        }
        if !source.keyDefinitions.isEmpty {
            lines.append("## Key Definitions")
            for def in source.keyDefinitions {
                lines.append("**\(def.term)**: \(def.definition)")
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Parse the translated markdown-like text back into structured notes
    private func parseTranslatedText(_ text: String) -> AIGeneratedNotes {
        let lines = text.components(separatedBy: "\n")
        var title = notes.title
        var summary = ""
        var sections: [AISection] = []
        var definitions: [AIDefinition] = []

        var currentHeading: String?
        var currentBullets: [String] = []
        var inDefinitions = false
        var summaryLines: [String] = []
        var pastTitle = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("# ") && !trimmed.hasPrefix("## ") {
                title = String(trimmed.dropFirst(2))
                pastTitle = true
            } else if trimmed.hasPrefix("## Key Definitions") || trimmed.hasPrefix("## Definiciones") {
                // Save current section
                if let heading = currentHeading {
                    sections.append(.init(heading: heading, bullets: currentBullets))
                    currentBullets = []
                    currentHeading = nil
                }
                inDefinitions = true
            } else if trimmed.hasPrefix("## ") {
                // Save previous section
                if let heading = currentHeading {
                    sections.append(.init(heading: heading, bullets: currentBullets))
                    currentBullets = []
                }
                currentHeading = String(trimmed.dropFirst(3))
                inDefinitions = false
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let bullet = String(trimmed.dropFirst(2))
                currentBullets.append(bullet)
            } else if inDefinitions && trimmed.hasPrefix("**") {
                // Parse **term**: definition
                if let colonRange = trimmed.range(of: "**: ") ?? trimmed.range(of: "**:") {
                    let term = String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 2)..<colonRange.lowerBound])
                    let def = String(trimmed[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    definitions.append(.init(term: term, definition: def))
                }
            } else if !trimmed.isEmpty && pastTitle && currentHeading == nil && !inDefinitions {
                summaryLines.append(trimmed)
            }
        }

        // Save last section
        if let heading = currentHeading {
            sections.append(.init(heading: heading, bullets: currentBullets))
        }

        summary = summaryLines.joined(separator: " ")
        if summary.isEmpty { summary = notes.summary }

        return AIGeneratedNotes(
            title: title,
            summary: summary,
            sections: sections.isEmpty ? notes.sections : sections,
            keyDefinitions: definitions.isEmpty ? notes.keyDefinitions : definitions
        )
    }
}

// MARK: - Translation Modifier (wraps iOS 17.4+ API)

private struct TranslationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let text: String
    let onTranslation: (String) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.4, macOS 14.4, *) {
            content
                .translationPresentation(
                    isPresented: $isPresented,
                    text: text
                ) { translatedText in
                    onTranslation(translatedText)
                }
        } else {
            content
        }
    }
}
