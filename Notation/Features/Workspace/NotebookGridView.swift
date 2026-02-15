import SwiftUI

struct NotebookGridView: View {
    let notebooks: [Notebook]
    let onSelect: (Notebook) -> Void
    let onDelete: (Notebook) -> Void
    let onRename: (Notebook, String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: Theme.Spacing.lg)
    ]

    var body: some View {
        if notebooks.isEmpty {
            EmptyStateView(
                icon: "book.closed",
                title: "No Notebooks",
                subtitle: "Create your first notebook to get started"
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
                    ForEach(notebooks) { notebook in
                        NotebookCardView(
                            notebook: notebook,
                            onTap: { onSelect(notebook) },
                            onDelete: { onDelete(notebook) },
                            onRename: { name in onRename(notebook, name) }
                        )
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }
}
