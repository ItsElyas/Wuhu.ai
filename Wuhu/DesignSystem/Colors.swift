import SwiftUI

extension Color {
    /// `0xRRGGBB`
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

enum AppColors {
    static let steps = Color.green
    static let heart = Color.red
    static let sleep = Color.indigo
    static let calories = Color.orange
    static let vitality = Color.teal
    static let effort = Color.purple
    static let readiness = Color.mint

    static let workedYellow = Color.yellow.opacity(0.55)
    static let soreYellow = Color.yellow
    static let injuredRed = Color.red
    static let healthyNeutral = Color.gray.opacity(0.35)
    static let skinTone = Color(red: 0.76, green: 0.60, blue: 0.48)

    // Home screen tokens from docs/UI_SPEC.md. Light mode is the reference.
    static let ink = Color(hex: 0x0B1020)
    static let textSecondary = Color(hex: 0x6B7794)
    static let textTertiary = Color(hex: 0x9AA3B5)
    static let accent = Color(hex: 0xE1453F)
    static let wearSlight = Color(hex: 0xEBCB6B)
    static let wearHigh = Color(hex: 0xDE8A3A)
    static let wearSevere = Color(hex: 0xA82F27)
    static let ringTrack = Color(hex: 0x0B1020).opacity(0.08)
    static let cardFill = Color.white.opacity(0.70)
    static let wearCardFill = Color.white.opacity(0.85)
    static let navRowFill = Color.white.opacity(0.30)
    static let cardStroke = Color.white.opacity(0.60)
    static let divider = Color(hex: 0x0B1020).opacity(0.06)
    static let fabFill = Color(hex: 0x0B0B0F)
    static let bodyBase = Color(hex: 0xD8D7D2)
    static let bodyOutline = Color(hex: 0x8A8A86).opacity(0.70)
    static let pillFill = Color.white.opacity(0.50)

    /// Shared with `MiniBodyFigure` and Body Map daily wear overlay.
    static func wearColor(for level: WearLevel) -> Color {
        switch level {
        case .none: return .clear
        case .slight: return wearSlight
        case .high: return wearHigh
        case .severe: return wearSevere
        }
    }

    static func bodyStatusColor(status: BodyStatus, intensity: Double) -> Color {
        switch status {
        case .healthy:
            return healthyNeutral
        case .worked:
            return Color.yellow.opacity(0.35 + 0.4 * intensity)
        case .sore:
            return Color.yellow.opacity(0.7 + 0.3 * intensity)
        case .injured:
            return injuredRed.opacity(0.75 + 0.25 * min(1, Double(intensity)))
        }
    }
}
