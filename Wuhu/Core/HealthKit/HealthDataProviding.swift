import Foundation

struct UserProfile: Equatable, Sendable {
    var ageYears: Int?
    var biologicalSex: String?
    var heightCm: Double?
    var weightKg: Double?
    var dateOfBirth: Date?
    /// First word is used in the Home greeting. Nil falls back to "there".
    var displayName: String? = nil
}

/// Abstraction so views never import HealthKit directly.
protocol HealthDataProviding: Sendable {
    func requestAuthorization() async throws
    func fetchDailyStats(for date: Date) async throws -> DailyStats
    func fetchDailyHistory(days: Int) async throws -> [DailyStats]
    func fetchWorkouts(from start: Date, to end: Date) async throws -> [ImportedWorkout]
    func fetchProfile() async throws -> UserProfile
}

struct ImportedWorkout: Equatable, Sendable, Identifiable {
    var id: UUID
    var type: String
    var startDate: Date
    var durationMinutes: Double
    var calories: Double?
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var distanceMiles: Double? = nil
}

enum HealthDataError: LocalizedError {
    case authorizationDenied
    case unavailable
    case noData
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Health access was denied. Enable it in Settings or use Mock Data."
        case .unavailable:
            return "Apple Health is not available on this device."
        case .noData:
            return "No health data found for this period."
        case .queryFailed(let message):
            return message
        }
    }
}
