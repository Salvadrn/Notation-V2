import SwiftUI

struct NotebookCardView: View {
    let notebook: Notebook
    let isTrashMode: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void
    let onToggleFavorite: () -> Void
    let onRestore: () -> Void

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false

    init(
        notebook: Notebook,
        isTrashMode: Bool = false,
        onTap: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onRename: @escaping (String) -> Void,
        onToggleFavorite: @escaping () -> Void = {},
        onRestore: @escaping () -> Void = {}
    ) {
        self.notebook = notebook
        self.isTrashMode = isTrashMode
        self.onTap = onTap
        self.onDelete = onDelete
        self.onRename = onRename
        self.onToggleFavorite = onToggleFavorite
        self.onRestore = onRestore
    }

    var body: some View {
        Button(action: {
            #if os(iOS)
            HapticService.light()
            #endif
            onTap()
        }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Cover
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .fill(Color(hex: notebook.coverColor).opacity(isTrashMode ? 0.5 : 1.0))
                        .frame(height: 120)
                        .overlay(alignment: .bottomLeading) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(Theme.Spacing.md)
                        }

                    // Favorite star
                    if notebook.isFavorite && !isTrashMode {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow)
                            .padding(8)
                    }
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

                    if isTrashMode, let days = notebook.daysUntilPurge {
                        Text("\(days) days remaining")
                            .font(.custom("Aptos", size: 11))
                            .foregroundStyle(Theme.Colors.destructive)
                    } else {
                        Text(notebook.updatedAt.displayString)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.sm)
            }
            .cardStyle()
            .opacity(isTrashMode ? 0.8 : 1.0)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isTrashMode {
                Button {
                    #if os(iOS)
                    HapticService.success()
                    #endif
                    onRestore()
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Permanently", systemImage: "trash.slash")
                }
            } else {
                Button {
                    #if os(iOS)
                    HapticService.light()
                    #endif
                    onToggleFavorite()
                } label: {
                    Label(
                        notebook.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: notebook.isFavorite ? "star.slash" : "star"
                    )
                }

                Button {
                    renameText = notebook.title
                    isRenaming = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }

                Button {
                    onTap() // Open notebook — export is available in notebook toolbar
                } label: {
                    Label("Export PDF", systemImage: "arrow.down.doc")
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            isTrashMode
                ? "Permanently delete \"\(notebook.title)\"?"
                : "Move \"\(notebook.title)\" to trash?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(isTrashMode ? "Delete Permanently" : "Move to Trash", role: .destructive) {
                #if os(iOS)
                HapticService.warning()
                #endif
                onDelete()
            }
        } message: {
            Text(isTrashMode
                ? "This notebook will be permanently deleted. This action cannot be undone."
                : "This notebook will be moved to Recently Deleted and auto-removed after 30 days."
            )
        }
    }
}
