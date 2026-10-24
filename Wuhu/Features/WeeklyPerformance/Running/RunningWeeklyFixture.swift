import Foundation

enum RunningWeeklyFixture {
    static let dateRange = "Sep 22 – Sep 28"
    static let titleLead = "Weekly Running"
    static let tagline = "More miles. Better consistency. A stronger you."
    static let runsCompleted = 5
    static let runsPossible = 7
    static let consistencyPercent = 71

    static let stats: [WeeklyMetric] = [
        WeeklyMetric(
            id: "miles",
            title: "Total Miles",
            value: "18.4 mi",
            systemImage: "figure.run",
            tintHex: 0xE15B9A,
            trend: "+3.2 mi",
            trendSymbol: "arrow.up",
            favorable: true,
            footnote: "vs. last week"
        ),
        WeeklyMetric(
            id: "calories",
            title: "Calories Burned",
            value: "2,450",
            systemImage: "flame.fill",
            tintHex: 0xF08A2C,
            trend: "+18%",
            trendSymbol: "arrow.up",
            favorable: true,
            footnote: "vs. last week"
        ),
        WeeklyMetric(
            id: "pace",
            title: "Avg. Mile Time",
            value: "8:12 /mi",
            systemImage: "stopwatch.fill",
            tintHex: 0x7A5AF8,
            trend: "−0:38",
            trendSymbol: "arrow.down",
            favorable: true,
            footnote: "vs. last week"
        ),
        WeeklyMetric(
            id: "hr",
            title: "Avg. Heart Rate",
            value: "158 bpm",
            systemImage: "heart.fill",
            tintHex: 0xE1453F,
            trend: "+4 bpm",
            trendSymbol: "arrow.up",
            favorable: false,
            footnote: "vs. last week"
        )
    ]

    static let days: [ConsistencyDay] = [
        ConsistencyDay(index: 0, weekday: "Mon", date: "Sep 22", miles: 3.2),
        ConsistencyDay(index: 1, weekday: "Tue", date: "Sep 23", miles: 4.0),
        ConsistencyDay(index: 2, weekday: "Wed", date: "Sep 24", miles: nil),
        ConsistencyDay(index: 3, weekday: "Thu", date: "Sep 25", miles: 5.1),
        ConsistencyDay(index: 4, weekday: "Fri", date: "Sep 26", miles: 3.0),
        ConsistencyDay(index: 5, weekday: "Sat", date: "Sep 27", miles: nil),
        ConsistencyDay(index: 6, weekday: "Sun", date: "Sep 28", miles: 3.1)
    ]

    static let paceSamples: [PaceHeartSample] = [
        PaceHeartSample(mile: 0.0, heartRate: 152, paceMinutes: 9.4),
        PaceHeartSample(mile: 0.5, heartRate: 148, paceMinutes: 9.0),
        PaceHeartSample(mile: 1.0, heartRate: 155, paceMinutes: 8.6),
        PaceHeartSample(mile: 1.5, heartRate: 166, paceMinutes: 8.9),
        PaceHeartSample(mile: 2.0, heartRate: 174, paceMinutes: 9.2),
        PaceHeartSample(mile: 2.5, heartRate: 168, paceMinutes: 8.5),
        PaceHeartSample(mile: 3.0, heartRate: 170, paceMinutes: 8.7),
        PaceHeartSample(mile: 3.5, heartRate: 162, paceMinutes: 9.0),
        PaceHeartSample(mile: 4.0, heartRate: 160, paceMinutes: 8.6),
        PaceHeartSample(mile: 4.5, heartRate: 158, paceMinutes: 8.8),
        PaceHeartSample(mile: 5.0, heartRate: 154, paceMinutes: 9.1)
    ]

    static let highlights: [RunningHighlight] = [
        RunningHighlight(
            id: "best",
            title: "Best Mile Time",
            detail: "Fastest mile this week",
            value: "7:28 /mi",
            note: "Sep 26 • 3.0 mi run",
            systemImage: "trophy.fill",
            tintHex: 0xE0A106
        ),
        RunningHighlight(
            id: "long",
            title: "Longest Run",
            detail: "Farthest distance this week",
            value: "5.1 mi",
            note: "Sep 25 • 8:20/mi",
            systemImage: "flag.fill",
            tintHex: 0x3B82F6
        ),
        RunningHighlight(
            id: "peak",
            title: "Peak Heart Rate",
            detail: "Highest during a run",
            value: "178 bpm",
            note: "Sep 25 • 5.1 mi run",
            systemImage: "heart.fill",
            tintHex: 0xE1453F
        )
    ]

    static var display: RunningWeekDisplay {
        RunningWeekDisplay(
            dateRange: dateRange,
            stats: stats,
            days: days,
            runsCompleted: runsCompleted,
            runsPossible: runsPossible,
            consistencyPercent: consistencyPercent,
            paceSamples: paceSamples,
            highlights: highlights,
            distanceNote: nil
        )
    }

    /// Maps a pace in minutes (6:00 at the top, 14:00 at the bottom) onto the heart-rate axis.
    static func paceChartY(_ minutes: Double) -> Double {
        let clamped = min(14, max(6, minutes))
        return 200 - ((clamped - 6) / 8) * 160
    }
}

struct ConsistencyDay: Identifiable {
    var index: Int
    var weekday: String
    var date: String
    var miles: Double?
    var id: Int { index }

    /// Rest days still draw a short gray bar instead of a zero-height mark.
    var barHeight: Double { miles ?? 1.15 }
    var label: String {
        guard let miles else { return "–" }
        return String(format: "%.1f", miles)
    }
}

struct PaceHeartSample: Identifiable {
    var mile: Double
    var heartRate: Double
    var paceMinutes: Double
    var id: Double { mile }
}

struct RunningHighlight: Identifiable {
    var id: String
    var title: String
    var detail: String
    var value: String
    var note: String
    var systemImage: String
    var tintHex: UInt32
}
