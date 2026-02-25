import SwiftUI

enum PageSwipeDirection: String, CaseIterable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"

    var icon: String {
        switch self {
        case .horizontal: return "arrow.left.arrow.right"
        case .vertical: return "arrow.up.arrow.down"
        }
    }

    #if os(iOS)
    var tabViewAxis: Axis {
        switch self {
        case .horizontal: return .horizontal
        case .vertical: return .vertical
        }
    }
    #endif
}

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    #if os(iOS)
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
    #endif
}

@MainActor
final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    private static let key = "notation_appearance_mode"
    private static let swipeKey = "notation_page_swipe_direction"

    @Published var currentMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: Self.key)
            applyAppearance()
        }
    }

    @Published var pageSwipeDirection: PageSwipeDirection {
        didSet {
            UserDefaults.standard.set(pageSwipeDirection.rawValue, forKey: Self.swipeKey)
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.key) ?? "System"
        self.currentMode = AppearanceMode(rawValue: stored) ?? .system
        let storedSwipe = UserDefaults.standard.string(forKey: Self.swipeKey) ?? "Horizontal"
        self.pageSwipeDirection = PageSwipeDirection(rawValue: storedSwipe) ?? .horizontal
    }

    func applyAppearance() {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = currentMode.userInterfaceStyle
        }
        #endif
    }
}
