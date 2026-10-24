import Foundation

enum DashboardMetric: String, Hashable, Identifiable {
    case steps, heartRate, sleep, calories
    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps: return "Steps"
        case .heartRate: return "Heart Rate"
        case .sleep: return "Sleep"
        case .calories: return "Calories"
        }
    }
}
