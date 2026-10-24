import Foundation

/// Visual-parity fixture for demo / mock mode. Not a training plan.
enum HomeFixture {
    static let reference = HomeState(
        firstName: "Elyas",
        plan: TodayPlan(split: .push, focus: "Upper body"),
        wslPresentation: WSLScorePresentation(headline: "High Tier Player", detail: "4.10 / 6.0"),
        wslTier: .bron,
        sleep: SleepSummary(
            totalHours: 462.0 / 60.0,
            deepHours: 110.0 / 60.0
        ),
        wear: [
            .leftShoulder: .slight,
            .rightShoulder: .slight,
            .chest: .high,
            .rightQuad: .slight,
            .rightKnee: .slight,
            .rightCalf: .slight,
            .rightAnkle: .slight,
            .rightFoot: .slight,
            .leftQuad: .severe,
            .leftKnee: .severe,
            .leftCalf: .severe,
            .leftAnkle: .severe,
            .leftFoot: .severe
        ],
        recommendation: DailyRecommendation(
            focus: "Upper body",
            sleepHours: 8,
            workoutMinutes: 55,
            calories: 2600
        ),
        steps: 8214,
        caloriesBurned: 1940,
        caloriesIn: 2100,
        nutritionNote: "P 140g  C 220g  F 70g",
        readinessPercent: 74,
        dataCaption: nil,
        phase: .loaded,
        daysWithData: 27
    )

    static let empty = HomeState(
        firstName: "there",
        plan: nil,
        wslPresentation: .collectingProfile,
        wslTier: .bron,
        sleep: nil,
        wear: [:],
        recommendation: HomeRecommendationFallback.packaged(.push).1,
        steps: nil,
        caloriesBurned: nil,
        caloriesIn: nil,
        nutritionNote: nil,
        readinessPercent: nil,
        dataCaption: "No Health samples for today.",
        phase: .empty,
        daysWithData: 2
    )
}
