import SwiftUI

enum Theme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color("Primary", bundle: nil)
        static let secondary = Color("Secondary", bundle: nil)

        static let primaryFallback = Color(hex: "#6366F1")
        static let secondaryFallback = Color(hex: "#8B5CF6")
        static let accent = Color(hex: "#F59E0B")
        static let destructive = Color(hex: "#EF4444")
        static let success = Color(hex: "#10B981")

        static let backgroundPrimary = Color(light: .white, dark: Color(hex: "#1C1C1E"))
        static let backgroundSecondary = Color(light: Color(hex: "#F5F5F7"), dark: Color(hex: "#2C2C2E"))
        static let backgroundTertiary = Color(light: Color(hex: "#EBEBEF"), dark: Color(hex: "#3A3A3C"))

        static let textPrimary = Color(light: Color(hex: "#1C1C1E"), dark: .white)
        static let textSecondary = Color(light: Color(hex: "#6B7280"), dark: Color(hex: "#9CA3AF"))
        static let textTertiary = Color(light: Color(hex: "#9CA3AF"), dark: Color(hex: "#6B7280"))

        static let separator = Color(light: Color(hex: "#E5E7EB"), dark: Color(hex: "#3A3A3C"))
        static let cardBackground = Color(light: .white, dark: Color(hex: "#2C2C2E"))
    }

    // MARK: - Typography (formal serif for titles, default for body)
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .serif)
        static let title = Font.system(size: 28, weight: .bold, design: .serif)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .serif)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .serif)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 20
        static let full: CGFloat = 999
    }

    // MARK: - Shadows
    enum Shadow {
        static let sm = ShadowStyle(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        static let md = ShadowStyle(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        static let lg = ShadowStyle(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
    }

    // MARK: - Animation
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.85)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    init(light: Color, dark: Color) {
        #if os(iOS)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(dark) : NSColor(light)
        })
        #endif
    }
}
