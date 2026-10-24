import Foundation

enum WearLevel: Int, Comparable, Sendable {
    case none = 0
    case slight = 1
    case high = 2
    case severe = 3

    static func < (lhs: WearLevel, rhs: WearLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .none: return "none"
        case .slight: return "slight"
        case .high: return "high"
        case .severe: return "severe"
        }
    }
}

enum Split: String, Codable, CaseIterable, Sendable {
    case push
    case pull
    case legs
    case upper
    case lower
    case fullBody = "full_body"
    case rest

    var dayTitle: String {
        switch self {
        case .push: return "Push Day"
        case .pull: return "Pull Day"
        case .legs: return "Leg Day"
        case .upper: return "Upper Day"
        case .lower: return "Lower Day"
        case .fullBody: return "Full Body Day"
        case .rest: return "Rest Day"
        }
    }

    /// Parts this split loads. Used so a plan never targets a severe or high area.
    var loadedParts: Set<BodyPart> {
        switch self {
        case .push:
            return [.chest, .leftShoulder, .rightShoulder, .leftTricep, .rightTricep]
        case .pull:
            return [.upperBack, .lowerBack, .leftBicep, .rightBicep]
        case .legs:
            return [.leftQuad, .rightQuad, .leftHamstring, .rightHamstring, .glutes, .leftCalf, .rightCalf]
        case .upper:
            return Split.push.loadedParts.union(Split.pull.loadedParts)
        case .lower:
            return Split.legs.loadedParts
        case .fullBody:
            return Split.upper.loadedParts.union(Split.lower.loadedParts)
        case .rest:
            return []
        }
    }
}

struct TodayPlan: Equatable, Sendable {
    var split: Split
    var focus: String
}

struct DailyRecommendation: Equatable, Sendable {
    var focus: String
    var sleepHours: Double
    var workoutMinutes: Int
    var calories: Int
}

enum HomePhase: Equatable, Sendable {
    case loading
    case loaded
    case empty
    case error(String)
}

struct HomeState: Equatable, Sendable {
    var firstName: String
    var plan: TodayPlan?
    var wslPresentation: WSLScorePresentation
    /// Legacy sheet fallback when Vitality scores exist without Wuhu profile.
    var wslTier: WSLRank
    var sleep: SleepSummary?
    var wear: [BodyPart: WearLevel]
    var recommendation: DailyRecommendation?
    var steps: Int?
    var caloriesBurned: Int?
    var caloriesIn: Int?
    var nutritionNote: String?
    var readinessPercent: Int?
    var dataCaption: String?
    var phase: HomePhase
    var daysWithData: Int

    static let loading = HomeState(
        firstName: "there",
        plan: nil,
        wslPresentation: .collectingProfile,
        wslTier: .placeholder,
        sleep: nil,
        wear: [:],
        recommendation: nil,
        steps: nil,
        caloriesBurned: nil,
        caloriesIn: nil,
        nutritionNote: nil,
        readinessPercent: nil,
        dataCaption: nil,
        phase: .loading,
        daysWithData: 0
    )
}

enum WearMapping {
    /// Maps one stored status to a wear level. Automatic sources never return `.severe`.
    static func level(
        status: BodyStatus,
        severity: Int,
        intensity: Double,
        source: BodyStatusSource
    ) -> WearLevel {
        if status == .injured {
            return source == .manual ? .severe : .high
        }
        if status == .sore {
            return severity >= 3 ? .high : .slight
        }
        if status == .worked {
            if intensity > 0.7 { return .high }
            if intensity > 0 { return .slight }
        }
        return .none
    }

    static func highest(_ levels: [WearLevel]) -> WearLevel {
        levels.max() ?? .none
    }
}

enum HomeFormat {
    static func sleep(minutes: Int) -> String {
        let clamped = max(0, minutes)
        let hours = clamped / 60
        let remainder = clamped % 60
        if hours == 0 {
            return "\(remainder)m"
        }
        if remainder == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainder)m"
    }

    static func sleep(hours: Double) -> String {
        sleep(minutes: Int((hours * 60).rounded()))
    }

    static func grouped(_ value: Int, locale: Locale = .current) -> String {
        value.formatted(.number.grouping(.automatic).locale(locale))
    }

    static func sleepTarget(_ hours: Double) -> String {
        sleep(hours: hours)
    }

    static func workoutTarget(_ minutes: Int) -> String {
        "\(minutes) min"
    }
}

struct GreetingCopy: Equatable, Sendable {
    var nameLine: String
    var continuation: String
    var accent: String?
    var suffix: String

    var spoken: String {
        if let accent {
            return "\(nameLine) \(continuation)\(accent)\(suffix)"
        }
        return "\(nameLine) \(continuation)"
    }

    static func firstName(from displayName: String?) -> String {
        let word = displayName?
            .split(whereSeparator: { $0.isWhitespace })
            .first
            .map(String.init) ?? ""
        return word.isEmpty ? "there" : word
    }

    static func make(firstName: String?, plan: TodayPlan?) -> GreetingCopy {
        let name = {
            let trimmed = firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? "there" : trimmed
        }()
        let nameLine = "Hello \(name),"
        guard let plan else {
            return GreetingCopy(
                nameLine: nameLine,
                continuation: "ready to train today?",
                accent: nil,
                suffix: ""
            )
        }
        if plan.split == .rest {
            return GreetingCopy(
                nameLine: nameLine,
                continuation: "we're taking a ",
                accent: "Rest Day",
                suffix: " today"
            )
        }
        return GreetingCopy(
            nameLine: nameLine,
            continuation: "we're training ",
            accent: plan.split.dayTitle,
            suffix: " today"
        )
    }
}

enum FigureSide: Equatable, Sendable {
    case viewerLeft
    case viewerRight
    case center
}

enum MiniBodyLayout {
    /// Person's right side is on the viewer's left in a front view.
    static func viewerSide(of part: BodyPart) -> FigureSide {
        if part.rawValue.hasPrefix("right") { return .viewerLeft }
        if part.rawValue.hasPrefix("left") { return .viewerRight }
        return .center
    }

    static let backOnly: Set<BodyPart> = [
        .upperBack, .lowerBack, .glutes,
        .leftHamstring, .rightHamstring,
        .leftTricep, .rightTricep
    ]
}

enum HomeRecommendationFallback {
    /// Rotates push / pull / legs and skips any split that loads a blocked part.
    static func plan(on day: Date, blocked: Set<BodyPart>, calendar: Calendar = .current) -> (TodayPlan, DailyRecommendation) {
        let order: [Split] = [.push, .pull, .legs]
        let dayIndex = calendar.ordinality(of: .day, in: .year, for: day) ?? 1
        let start = (dayIndex - 1) % order.count
        for offset in 0..<order.count {
            let split = order[(start + offset) % order.count]
            if split.loadedParts.isDisjoint(with: blocked) {
                return packaged(split)
            }
        }
        return packaged(.rest)
    }

    static func packaged(_ split: Split) -> (TodayPlan, DailyRecommendation) {
        let focus: String
        let minutes: Int
        let calories: Int
        switch split {
        case .push, .upper:
            focus = "Upper body"
            minutes = 55
            calories = 2600
        case .pull:
            focus = "Pull"
            minutes = 50
            calories = 2400
        case .legs, .lower:
            focus = "Lower body"
            minutes = 50
            calories = 2500
        case .fullBody:
            focus = "Full body"
            minutes = 45
            calories = 2400
        case .rest:
            focus = "Rest"
            minutes = 0
            calories = 2000
        }
        let recommendation = DailyRecommendation(
            focus: focus,
            sleepHours: 8,
            workoutMinutes: minutes,
            calories: calories
        )
        return (TodayPlan(split: split, focus: focus), recommendation)
    }
}
