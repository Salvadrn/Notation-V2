import SwiftUI

struct NotebookCardView: View {
    let notebook: Notebook
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Cover
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Color(hex: notebook.coverColor))
                    .frame(height: 120)
                    .overlay(alignment: .bottomLeading) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(Theme.Spacing.md)
                    }

                // Title
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    if isRenaming {
                        TextField("Title", text: $renameText, onCommit: {
                            onRename(renameText)
                            isRenaming = false
                        })
                        .textFieldStyle(.plain)
                        .font(Theme.Typography.headline)
                    } else {
                        Text(notebook.title)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(2)
                    }

                    Text(notebook.updatedAt.displayString)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.sm)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                renameText = notebook.title
                isRenaming = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button {
                // Export placeholder
            } label: {
                Label("Export PDF", systemImage: "arrow.down.doc")
            }

            Divider()

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete \"\(notebook.title)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("All sections and pages in this notebook will be permanently deleted.")
        }
    }
}
