#if os(iOS)
import UIKit

enum HapticService {
    // MARK: - Impact Feedback
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func rigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    // MARK: - Notification Feedback
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Selection Feedback
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
#endif
