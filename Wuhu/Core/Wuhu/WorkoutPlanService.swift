import Foundation

enum WorkoutPlanService {
    static func prescription(
        for profile: AthleteOnboardingEngine.PlayerProfile?,
        on date: Date = .now,
        engine: WorkoutDatabaseEngine
    ) -> WorkoutDatabaseEngine.ExercisePrescription? {
        guard let profile else { return nil }
        let day = AthleteOnboardingEngine.DayOfWeek.from(date: date)
        return engine.fetchWorkouts(for: profile.selectedSport).first { $0.dayOfWeek == day }
    }

    static func todayPillLabel(
        profile: AthleteOnboardingEngine.PlayerProfile?,
        plan: TodayPlan?,
        date: Date = .now
    ) -> String {
        let weekday = AthleteOnboardingEngine.DayOfWeek.from(date: date).shortLabel
        if let plan, plan.split != .rest {
            return "Today's Workout (\(weekday): \(plan.focus))"
        }
        if let profile {
            return "Today's Workout (\(weekday): \(profile.selectedSport.rawValue))"
        }
        return "Today's Workout (\(weekday))"
    }
}
