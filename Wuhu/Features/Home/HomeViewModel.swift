import Foundation
import SwiftData

@MainActor
@Observable
final class HomeViewModel {
    var state: HomeState = .loading

    func reload(app: AppEnvironment, records: [BodyPartStatusRecord], modelContext: ModelContext? = nil) {
        if let modelContext {
            app.refreshWear(modelContext: modelContext, bodyRecords: records)
        }
        if modelContext != nil || app.autoWSL == nil {
            app.refreshWSL(modelContext: modelContext)
        }
        state = Self.makeState(app: app, records: records)
    }

    static func makeState(app: AppEnvironment, records: [BodyPartStatusRecord]) -> HomeState {
        let days = app.lastSnapshot?.dataQuality.daysWithData ?? 0
        if app.isLoading {
            return .loading
        }

        let wearResult = app.wearTearResult ?? WearTearEngine.compute(
            WearTearInput(
                bodyRecords: records,
                workouts: AppEnvironment.wearWorkoutEvents(imported: app.recentWorkouts, logged: []),
                sleepHoursLastNight: app.today?.sleep?.totalHours
            )
        )
        let fullWear = wearResult.wear
        let wear = fullWear.filter { $0.value != .none }
        let blocked = Set(fullWear.filter { $0.value == .high || $0.value == .severe }.map(\.key))
        let readiness = ReadinessEstimator.score(
            wearResult: wearResult,
            sleepHours: app.today?.sleep?.totalHours,
            scoreResult: app.latestScores
        )
        let resolved = resolvePlan(
            score: app.latestScores,
            blocked: blocked,
            readiness: readiness,
            wear: fullWear
        )
        let sleep = app.today?.sleep
        let steps = app.today?.steps
        let calories = burnedCalories(app.today)
        let intake = app.nutrition?.todayCaloriesIn
        let note = app.nutrition?.macroLine

        let hasNumbers = sleep != nil || steps != nil || calories != nil || intake != nil
        var phase: HomePhase = hasNumbers ? .loaded : .empty
        var caption: String?
        if let message = app.errorMessage {
            phase = .error(message)
        } else if let hint = app.healthAccessHint {
            caption = hint
        } else if !hasNumbers {
            caption = "No Health samples for today. Pull to refresh after granting Apple Health access."
        }

        return HomeState(
            firstName: GreetingCopy.firstName(from: app.profile.displayName),
            plan: resolved?.0,
            wslPresentation: app.wslPresentation,
            wslTier: .placeholder,
            sleep: sleep,
            wear: wear,
            recommendation: resolved?.1,
            steps: steps,
            caloriesBurned: calories,
            caloriesIn: intake,
            nutritionNote: note,
            readinessPercent: readiness,
            dataCaption: caption,
            phase: phase,
            daysWithData: days
        )
    }

    /// Active plus resting only when at least one sample exists.
    static func burnedCalories(_ day: DailyStats?) -> Int? {
        guard let day, day.activeCalories != nil || day.restingCalories != nil else { return nil }
        return Int(((day.activeCalories ?? 0) + (day.restingCalories ?? 0)).rounded())
    }

    static func resolvePlan(
        score: ScoreResult?,
        blocked: Set<BodyPart>,
        readiness: Int,
        wear: [BodyPart: WearLevel]
    ) -> (TodayPlan, DailyRecommendation)? {
        if let validated = score?.validatedDailyPlan(),
           validated.0.loadedParts.isDisjoint(with: blocked) {
            return (TodayPlan(split: validated.0, focus: validated.1.focus), validated.1)
        }
        return WearRecommendationPlanner.recommendation(readiness: readiness, wear: wear, blocked: blocked)
    }
}
