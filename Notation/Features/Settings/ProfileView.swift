import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var isEditing = false
    @State private var editedName = ""

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            Circle()
                .fill(Theme.Colors.primaryFallback.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(initials)
                        .font(Theme.Typography.title3)
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }

            VStack(alignment: .leading, spacing: 2) {
                if isEditing {
                    TextField("Full Name", text: $editedName, onCommit: {
                        Task { await viewModel.updateProfile(fullName: editedName) }
                        isEditing = false
                    })
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.headline)
                } else {
                    Text(viewModel.profile.fullName ?? "User")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Text(tierBadge)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(viewModel.profile.isPro ? Theme.Colors.accent : Theme.Colors.textTertiary)
            }

            Spacer()

            Button {
                editedName = viewModel.profile.fullName ?? ""
                isEditing.toggle()
            } label: {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    private var initials: String {
        guard let name = viewModel.profile.fullName, !name.isEmpty else { return "?" }
        let components = name.components(separatedBy: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }

    private var tierBadge: String {
        viewModel.profile.isPro ? "Pro Member" : "Free Plan"
    }
}
