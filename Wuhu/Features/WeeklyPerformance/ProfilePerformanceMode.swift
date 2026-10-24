import Foundation

/// Which weekly performance layout to show. Profile sports are not built yet.
enum WeeklyPerformanceMode: String, CaseIterable, Identifiable, Sendable {
    case running
    case powerlifting

    var id: String { rawValue }

    var previewTitle: String {
        switch self {
        case .running: return "Running"
        case .powerlifting: return "Powerlifting"
        }
    }
}

/// Placeholder until onboarding profile chooses a sport.
@MainActor
@Observable
final class ProfilePreferences {
    private static let key = "weeklyPerformanceMode"

    /// TODO: drive this from the signed-in profile's sports. Defaults to running.
    var weeklyPerformanceMode: WeeklyPerformanceMode {
        didSet {
            UserDefaults.standard.set(weeklyPerformanceMode.rawValue, forKey: Self.key)
        }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.key) ?? ""
        weeklyPerformanceMode = WeeklyPerformanceMode(rawValue: stored) ?? .running
    }
}
