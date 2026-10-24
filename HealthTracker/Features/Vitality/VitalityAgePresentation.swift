import SwiftUI

/// Pure formatting helpers (no SwiftUI view builders) for Vitality Age UI.
enum VitalityAgePresentation {
    static func deltaLabel(delta: Double) -> String {
        if delta < 0 {
            return String(format: "%.1f years younger", abs(delta))
        }
        return String(format: "%.1f years older", delta)
    }

    static func deltaColor(delta: Double) -> Color {
        delta < 0 ? .green : .orange
    }

    static func effortText(score: Double?, scaleMax: Double?) -> String {
        guard let score else { return "-" }
        return String(format: "%.1f / %.0f", score, scaleMax ?? 21)
    }

    static func scoreText(_ score: Double?) -> String {
        guard let score else { return "-" }
        return "\(Int(score))"
    }
}
