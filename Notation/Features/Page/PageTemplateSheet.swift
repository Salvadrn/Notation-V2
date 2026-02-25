import SwiftUI

enum PageTemplate: String, CaseIterable, Identifiable {
    case blank = "Blank"
    case cornell = "Cornell Notes"
    case todo = "To-Do List"
    case meeting = "Meeting Notes"
    case grid = "Grid Paper"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .blank: return "doc"
        case .cornell: return "rectangle.split.2x1"
        case .todo: return "checklist"
        case .meeting: return "person.3"
        case .grid: return "grid"
        }
    }

    var description: String {
        switch self {
        case .blank: return "Start with a clean page"
        case .cornell: return "Cue column, notes area, and summary section"
        case .todo: return "Checkboxes and task list format"
        case .meeting: return "Date, attendees, agenda, and action items"
        case .grid: return "Graph paper style with grid lines"
        }
    }

    /// Generate pre-filled TextContent for this template
    var textContent: TextContent {
        switch self {
        case .blank:
            return .empty

        case .cornell:
            return TextContent(blocks: [
                .heading("Cornell Notes"),
                .paragraph(""),
                .heading("Key Points"),
                .bullet("Main concept 1"),
                .bullet("Main concept 2"),
                .paragraph(""),
                .heading("Notes"),
                .paragraph("Write your detailed notes here..."),
                .paragraph(""),
                .heading("Summary"),
                .paragraph("Summarize the key takeaways in 2-3 sentences.")
            ])

        case .todo:
            return TextContent(blocks: [
                .heading("To-Do List"),
                .paragraph(""),
                TextBlock(id: UUID(), text: "High Priority", style: .subheading),
                .bullet("Task 1"),
                .bullet("Task 2"),
                .paragraph(""),
                TextBlock(id: UUID(), text: "Medium Priority", style: .subheading),
                .bullet("Task 3"),
                .bullet("Task 4"),
                .paragraph(""),
                TextBlock(id: UUID(), text: "Low Priority", style: .subheading),
                .bullet("Task 5")
            ])

        case .meeting:
            return TextContent(blocks: [
                .heading("Meeting Notes"),
                .paragraph(""),
                TextBlock(id: UUID(), text: "Meeting Info", style: .subheading),
                .bullet("Date: "),
                .bullet("Attendees: "),
                .bullet("Location: "),
                .paragraph(""),
                TextBlock(id: UUID(), text: "Agenda", style: .subheading),
                TextBlock(id: UUID(), text: "1. ", style: .numbered),
                TextBlock(id: UUID(), text: "2. ", style: .numbered),
                TextBlock(id: UUID(), text: "3. ", style: .numbered),
                .paragraph(""),
                TextBlock(id: UUID(), text: "Discussion Notes", style: .subheading),
                .paragraph(""),
                .paragraph(""),
                TextBlock(id: UUID(), text: "Action Items", style: .subheading),
                .bullet("[ ] Action item 1 — Owner: "),
                .bullet("[ ] Action item 2 — Owner: "),
                .paragraph(""),
                TextBlock(id: UUID(), text: "Next Steps", style: .subheading),
                .paragraph("Follow-up meeting: ")
            ])

        case .grid:
            // Grid template just has a title — the grid is visual via the drawing layer
            return TextContent(blocks: [
                .heading("Grid Paper"),
                .paragraph("")
            ])
        }
    }
}

struct PageTemplateSheet: View {
    let onSelect: (PageTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(PageTemplate.allCases) { template in
                        Button {
                            #if os(iOS)
                            HapticService.light()
                            #endif
                            onSelect(template)
                            dismiss()
                        } label: {
                            VStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.Colors.backgroundSecondary)
                                        .frame(height: 90)

                                    Image(systemName: template.icon)
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundStyle(Theme.Colors.primaryFallback)
                                }

                                VStack(spacing: 4) {
                                    Text(template.rawValue)
                                        .font(.custom("Aptos-Bold", size: 14))
                                        .foregroundStyle(Theme.Colors.textPrimary)

                                    Text(template.description)
                                        .font(.custom("Aptos", size: 11))
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(12)
                            .background(Theme.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.separator.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Page Template")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
