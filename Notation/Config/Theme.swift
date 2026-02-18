import SwiftUI

enum Theme {
    // MARK: - Colors (Gray Palette)
    enum Colors {
        static let primary = Color(hex: "#4F4F4F")
        static let secondary = Color(hex: "#6E6E6E")

        static let primaryFallback = Color(hex: "#3A3A3A")
        static let secondaryFallback = Color(hex: "#5C5C5C")
        static let accent = Color(hex: "#808080")
        static let destructive = Color(hex: "#8B0000")
        static let success = Color(hex: "#4A4A4A")

        static let backgroundPrimary = Color(light: .white, dark: Color(hex: "#1C1C1E"))
        static let backgroundSecondary = Color(light: Color(hex: "#F2F2F2"), dark: Color(hex: "#2C2C2E"))
        static let backgroundTertiary = Color(light: Color(hex: "#E8E8E8"), dark: Color(hex: "#3A3A3C"))

        static let textPrimary = Color(light: Color(hex: "#1A1A1A"), dark: .white)
        static let textSecondary = Color(light: Color(hex: "#5C5C5C"), dark: Color(hex: "#A0A0A0"))
        static let textTertiary = Color(light: Color(hex: "#999999"), dark: Color(hex: "#666666"))

        static let separator = Color(light: Color(hex: "#D9D9D9"), dark: Color(hex: "#3A3A3C"))
        static let cardBackground = Color(light: .white, dark: Color(hex: "#2C2C2E"))
    }

    // MARK: - Typography (Aptos)
    enum Typography {
        static let largeTitle = Font.custom("Aptos-Bold", size: 34)
        static let title = Font.custom("Aptos-Bold", size: 28)
        static let title2 = Font.custom("Aptos-Bold", size: 22)
        static let title3 = Font.custom("Aptos-Bold", size: 20)
        static let headline = Font.custom("Aptos-Bold", size: 17)
        static let body = Font.custom("Aptos", size: 17)
        static let callout = Font.custom("Aptos", size: 16)
        static let subheadline = Font.custom("Aptos", size: 15)
        static let footnote = Font.custom("Aptos", size: 13)
        static let caption = Font.custom("Aptos-Light", size: 12)
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
