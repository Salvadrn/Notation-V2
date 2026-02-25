import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .shadow(
                color: Theme.Shadow.md.color,
                radius: Theme.Shadow.md.radius,
                x: Theme.Shadow.md.x,
                y: Theme.Shadow.md.y
            )
    }

    func softShadow() -> some View {
        self.shadow(
            color: Theme.Shadow.sm.color,
            radius: Theme.Shadow.sm.radius,
            x: Theme.Shadow.sm.x,
            y: Theme.Shadow.sm.y
        )
    }

    func prominentShadow() -> some View {
        self.shadow(
            color: Theme.Shadow.lg.color,
            radius: Theme.Shadow.lg.radius,
            x: Theme.Shadow.lg.x,
            y: Theme.Shadow.lg.y
        )
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func onFirstAppear(perform action: @escaping () async -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }

    func sheetStyle() -> some View {
        self
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Theme.Radius.xl)
    }

    #if os(iOS)
    func withHaptic(_ type: HapticType = .light) -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            switch type {
            case .light: HapticService.light()
            case .medium: HapticService.medium()
            case .success: HapticService.success()
            case .selection: HapticService.selection()
            case .error: HapticService.error()
            }
        })
    }
    #endif
}

#if os(iOS)
enum HapticType {
    case light, medium, success, selection, error
}
#endif

private struct FirstAppearModifier: ViewModifier {
    let action: () async -> Void
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content.task {
            guard !hasAppeared else { return }
            hasAppeared = true
            await action()
        }
    }
}
