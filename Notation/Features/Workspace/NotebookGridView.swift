import SwiftUI

struct NotebookGridView: View {
    let notebooks: [Notebook]
    let isTrashMode: Bool
    let onSelect: (Notebook) -> Void
    let onDelete: (Notebook) -> Void
    let onRename: (Notebook, String) -> Void
    let onToggleFavorite: (Notebook) -> Void
    let onRestore: (Notebook) -> Void

    init(
        notebooks: [Notebook],
        isTrashMode: Bool = false,
        onSelect: @escaping (Notebook) -> Void,
        onDelete: @escaping (Notebook) -> Void,
        onRename: @escaping (Notebook, String) -> Void,
        onToggleFavorite: @escaping (Notebook) -> Void = { _ in },
        onRestore: @escaping (Notebook) -> Void = { _ in }
    ) {
        self.notebooks = notebooks
        self.isTrashMode = isTrashMode
        self.onSelect = onSelect
        self.onDelete = onDelete
        self.onRename = onRename
        self.onToggleFavorite = onToggleFavorite
        self.onRestore = onRestore
    }

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: Theme.Spacing.lg)
    ]

    var body: some View {
        if notebooks.isEmpty {
            if isTrashMode {
                EmptyStateView(
                    icon: "trash",
                    title: "Trash is Empty",
                    subtitle: "Deleted notebooks will appear here for 30 days"
                )
            } else {
                EmptyStateView(
                    icon: "book.closed",
                    title: "No Notebooks",
                    subtitle: "Create your first notebook to get started"
                )
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
                    ForEach(notebooks) { notebook in
                        NotebookCardView(
                            notebook: notebook,
                            isTrashMode: isTrashMode,
                            onTap: { onSelect(notebook) },
                            onDelete: { onDelete(notebook) },
                            onRename: { name in onRename(notebook, name) },
                            onToggleFavorite: { onToggleFavorite(notebook) },
                            onRestore: { onRestore(notebook) }
                        )
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }
}
