import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isPresented: Bool

    enum ToastType {
        case success
        case error
        case info
        case warning

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return Theme.Colors.success
            case .error: return Theme.Colors.destructive
            case .info: return Theme.Colors.primaryFallback
            case .warning: return Theme.Colors.accent
            }
        }
    }

    var body: some View {
        if isPresented {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: type.icon)
                    .foregroundStyle(type.color)

                Text(message)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Button {
                    withAnimation { isPresented = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .softShadow()
            .padding(.horizontal, Theme.Spacing.lg)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { isPresented = false }
                }
            }
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastView.ToastType

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            ToastView(message: message, type: type, isPresented: $isPresented)
                .padding(.top, Theme.Spacing.lg)
        }
        .animation(Theme.Animation.smooth, value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, type: ToastView.ToastType = .info) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, type: type))
    }
}
