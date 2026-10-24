import Foundation

enum PowerliftingWeeklyFixture {
    static let dateRange = "Sep 22 – Sep 28"
    static let titleLead = "Weekly Powerlifting"
    static let tagline = "Bigger lifts. Stronger you."
    static let lastWorkoutWhen = "Sep 27 • 1h 12m"

    static let stats: [WeeklyMetric] = [
        WeeklyMetric(
            id: "lifts",
            title: "Total Lifts",
            value: "16",
            systemImage: "dumbbell.fill",
            tintHex: 0x7A5AF8,
            trend: "+3",
            trendSymbol: "arrow.up",
            favorable: true,
            footnote: "vs. last week"
        ),
        WeeklyMetric(
            id: "volume",
            title: "Total Volume",
            value: "12,450 lbs",
            systemImage: "flame.fill",
            tintHex: 0xE1453F,
            trend: "+12%",
            trendSymbol: "arrow.up",
            favorable: true,
            footnote: "vs. last week"
        ),
        WeeklyMetric(
            id: "time",
            title: "Total Training Time",
            value: "4h 32m",
            systemImage: "stopwatch.fill",
            tintHex: 0x7A5AF8,
            trend: "+18%",
            trendSymbol: "arrow.up",
            favorable: true,
            footnote: "vs. last week"
        ),
        WeeklyMetric(
            id: "weight",
            title: "Avg. Bodyweight",
            value: "194 lbs",
            systemImage: "scalemass.fill",
            tintHex: 0x14B8A6,
            trend: "−1 lb",
            trendSymbol: "arrow.down",
            favorable: true,
            footnote: "vs. last week"
        )
    ]

    static let lifts: [LiftProgress] = [
        LiftProgress(id: "bench", name: "Bench Press", value: "155 lbs", trend: "+5 lbs", trendSymbol: "arrow.up", favorable: true, systemImage: "figure.strengthtraining.traditional", tintHex: 0xE15B9A),
        LiftProgress(id: "squat", name: "Squat", value: "205 lbs", trend: "+10 lbs", trendSymbol: "arrow.up", favorable: true, systemImage: "figure.strengthtraining.functional", tintHex: 0x7A5AF8),
        LiftProgress(id: "deadlift", name: "Deadlift", value: "275 lbs", trend: "+15 lbs", trendSymbol: "arrow.up", favorable: true, systemImage: "dumbbell.fill", tintHex: 0x6366F1),
        LiftProgress(id: "clean", name: "Power Clean", value: "155 lbs", trend: "−5 lbs", trendSymbol: "arrow.down", favorable: false, systemImage: "dumbbell.fill", tintHex: 0x14B8A6)
    ]

    static let prs: [LiftRecord] = [
        LiftRecord(id: "bench", name: "Bench Press", value: "155 lbs", note: "Sep 26"),
        LiftRecord(id: "squat", name: "Squat", value: "205 lbs", note: "Sep 24"),
        LiftRecord(id: "deadlift", name: "Deadlift", value: "275 lbs", note: "Sep 22"),
        LiftRecord(id: "clean", name: "Power Clean", value: "155 lbs", note: "Sep 20")
    ]

    static let lastWorkout: [LiftRecord] = [
        LiftRecord(id: "bench", name: "Bench Press", value: "4 × 6", note: "135 lbs"),
        LiftRecord(id: "squat", name: "Squat", value: "4 × 5", note: "185 lbs"),
        LiftRecord(id: "deadlift", name: "Deadlift", value: "3 × 5", note: "225 lbs"),
        LiftRecord(id: "clean", name: "Power Clean", value: "5 × 3", note: "135 lbs")
    ]
}

struct LiftProgress: Identifiable {
    var id: String
    var name: String
    var value: String
    var trend: String
    var trendSymbol: String
    var favorable: Bool
    var systemImage: String
    var tintHex: UInt32
}

struct LiftRecord: Identifiable {
    var id: String
    var name: String
    var value: String
    var note: String
}
