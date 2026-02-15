import SwiftUI

struct AIResultView: View {
    let notes: AIGeneratedNotes

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Title
            Text(notes.title)
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)

            // Summary
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Summary", systemImage: "doc.text")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryFallback)

                Text(notes.summary)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.primaryFallback.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))

            // Sections
            ForEach(notes.sections) { section in
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
            if !notes.keyDefinitions.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Label("Key Definitions", systemImage: "bookmark.fill")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.accent)

                    ForEach(notes.keyDefinitions) { definition in
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

            // Add to notebook button
            Button {
                // Will be connected to insert notes into a page
            } label: {
                Label("Add to Notebook", systemImage: "plus.rectangle.on.folder")
                    .font(Theme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.primaryFallback)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            }
        }
    }
}
