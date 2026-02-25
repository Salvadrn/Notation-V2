import SwiftUI

struct FolderRowView: View {
    let folder: Folder
    let allFolders: [Folder]
    @Binding var expandedIDs: Set<UUID>
    let onSelect: (Folder) -> Void
    let onRename: (Folder, String) -> Void
    let onDelete: (Folder) -> Void

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false

    private var children: [Folder] {
        allFolders.filter { $0.parentId == folder.id }
    }

    private var isExpanded: Bool {
        expandedIDs.contains(folder.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Theme.Spacing.sm) {
                // Expand/collapse chevron
                if !children.isEmpty {
                    Button {
                        withAnimation(Theme.Animation.quick) {
                            if isExpanded {
                                expandedIDs.remove(folder.id)
                            } else {
                                expandedIDs.insert(folder.id)
                            }
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(width: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 16)
                }

                Image(systemName: isExpanded ? "folder.fill" : "folder")
                    .foregroundStyle(Theme.Colors.primaryFallback)

                if isRenaming {
                    TextField("Folder name", text: $renameText, onCommit: {
                        onRename(folder, renameText)
                        isRenaming = false
                    })
                    .textFieldStyle(.plain)
                } else {
                    Text(folder.name)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect(folder)
            }
            .contextMenu {
                Button {
                    renameText = folder.name
                    isRenaming = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .confirmationDialog(
                "Delete \"\(folder.name)\"?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete(folder)
                }
            } message: {
                Text("This will also delete all contents inside this folder.")
            }

            // Children
            if isExpanded {
                ForEach(children) { child in
                    FolderRowView(
                        folder: child,
                        allFolders: allFolders,
                        expandedIDs: $expandedIDs,
                        onSelect: onSelect,
                        onRename: onRename,
                        onDelete: onDelete
                    )
                    .padding(.leading, Theme.Spacing.lg)
                }
            }
        }
    }
}
