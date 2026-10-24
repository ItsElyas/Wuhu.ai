import SwiftUI

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
