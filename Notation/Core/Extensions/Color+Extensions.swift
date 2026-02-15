import SwiftUI

extension Color {
    // Notebook cover color presets
    static let coverColors: [String] = [
        "#6366F1", // Indigo
        "#8B5CF6", // Violet
        "#EC4899", // Pink
        "#EF4444", // Red
        "#F59E0B", // Amber
        "#10B981", // Emerald
        "#3B82F6", // Blue
        "#06B6D4", // Cyan
        "#84CC16", // Lime
        "#F97316", // Orange
        "#6B7280", // Gray
        "#1F2937", // Dark
    ]

    static func fromHex(_ hex: String) -> Color {
        Color(hex: hex)
    }

    var hexString: String {
        #if os(iOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
        #elseif os(macOS)
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else { return "#000000" }
        return String(
            format: "#%02X%02X%02X",
            Int(rgbColor.redComponent * 255),
            Int(rgbColor.greenComponent * 255),
            Int(rgbColor.blueComponent * 255)
        )
        #endif
    }
}
