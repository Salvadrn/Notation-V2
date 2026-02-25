import SwiftUI

struct SectionTabBar: View {
    let sections: [Section]
    let selectedSection: Section?
    let onSelect: (Section) -> Void
    let onAdd: () -> Void
    let onRename: (Section, String) -> Void
    let onDelete: (Section) -> Void

    @State private var renamingSection: Section?
    @State private var renameText = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(sections) { section in
                    sectionTab(section)
                }

                // Add section button
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(Theme.Colors.backgroundSecondary)
    }

    @ViewBuilder
    private func sectionTab(_ section: Section) -> some View {
        let isSelected = selectedSection?.id == section.id

        Button {
            onSelect(section)
        } label: {
            Group {
                if renamingSection?.id == section.id {
                    TextField("Section", text: $renameText, onCommit: {
                        onRename(section, renameText)
                        renamingSection = nil
                    })
                    .textFieldStyle(.plain)
                    .frame(minWidth: 60)
                } else {
                    Text(section.title)
                        .lineLimit(1)
                }
            }
            .font(isSelected ? Theme.Typography.headline : Theme.Typography.subheadline)
            .foregroundStyle(isSelected ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                isSelected
                    ? Theme.Colors.primaryFallback.opacity(0.1)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                renameText = section.title
                renamingSection = section
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete(section)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
