import Foundation

/// Adjusts daily targets from wear load and readiness.
enum WearRecommendationPlanner {
    static func recommendation(
        readiness: Int,
        wear: [BodyPart: WearLevel],
        blocked: Set<BodyPart>,
        on day: Date = .now
    ) -> (TodayPlan, DailyRecommendation) {
        let heavyCount = wear.values.filter { $0 >= .high }.count
        let severeCount = wear.values.filter { $0 == .severe }.count

        var (plan, base) = HomeRecommendationFallback.plan(on: day, blocked: blocked)

        let readinessFactor = Double(readiness)
        let workoutMinutes = max(0, min(70, Int((55 - Double(heavyCount) * 7 - Double(severeCount) * 10 - (100 - readinessFactor) * 0.15).rounded())))
        let sleepHours = min(9.5, max(7.0, 7.5 + Double(max(0, 72 - readiness)) / 18.0 + Double(heavyCount) * 0.15))

        let calories = max(1_800, base.calories - heavyCount * 120 - max(0, 70 - readiness) * 4)

        if severeCount >= 2 || readiness < 45 {
            plan = TodayPlan(split: .rest, focus: "Recovery")
        } else if lowerWear(wear) > upperWear(wear) + 0.2 {
            plan = TodayPlan(split: .upper, focus: "Upper body")
        } else if upperWear(wear) > lowerWear(wear) + 0.2 {
            plan = TodayPlan(split: .legs, focus: "Lower body")
        }

        let recommendation = DailyRecommendation(
            focus: plan.focus,
            sleepHours: sleepHours,
            workoutMinutes: plan.split == .rest ? 0 : workoutMinutes,
            calories: calories
        )
        return (plan, recommendation)
    }

    private static func lowerWear(_ wear: [BodyPart: WearLevel]) -> Double {
        let parts: [BodyPart] = [.leftQuad, .rightQuad, .leftHamstring, .rightHamstring, .glutes, .leftKnee, .rightKnee]
        return meanLevel(parts.map { wear[$0] ?? .none })
    }

    private static func upperWear(_ wear: [BodyPart: WearLevel]) -> Double {
        let parts: [BodyPart] = [.chest, .upperBack, .leftShoulder, .rightShoulder]
        return meanLevel(parts.map { wear[$0] ?? .none })
    }

    private static func meanLevel(_ levels: [WearLevel]) -> Double {
        guard !levels.isEmpty else { return 0 }
        let sum = levels.reduce(0.0) { $0 + Double($1.rawValue) }
        return sum / Double(levels.count)
    }
}
