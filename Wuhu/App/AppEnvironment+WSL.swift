import Foundation
import SwiftData

extension AppEnvironment {
    /// The WSL shown everywhere: an explicit profile evaluation wins, otherwise the auto estimate.
    var currentWSLEvaluation: WSLCompositeEvaluation? {
        playerProfileStore.profile?.wslEvaluation ?? autoWSL?.evaluation
    }

    var wslPresentation: WSLScorePresentation {
        guard let evaluation = currentWSLEvaluation else { return .collectingProfile }
        return WSLScorePresentation.from(evaluation: evaluation)
    }

    /// Recomputes the auto WSL from profile, Health, settings, workouts, and Workout Hub sets.
    /// Cheap and synchronous; safe to call on every Home reload.
    func refreshWSL(modelContext: ModelContext?) {
        let liftSets: [WSLAutoEvaluator.LiftSet] = {
            guard let modelContext,
                  let logs = try? modelContext.fetch(FetchDescriptor<HubSetLog>()) else { return [] }
            return logs.compactMap { log in
                guard log.isCompleted, !log.usesBodyweight,
                      let weight = log.weightLbs, let name = log.exercise?.name else { return nil }
                return WSLAutoEvaluator.LiftSet(exerciseName: name, weightLbs: weight, reps: log.reps)
            }
        }()

        let logged: [ImportedWorkout] = {
            guard let modelContext,
                  let records = try? modelContext.fetch(FetchDescriptor<WorkoutRecord>()) else { return [] }
            let importedIDs = Set(recentWorkouts.map(\.startDate))
            return records
                .filter { !importedIDs.contains($0.startDate) }
                .map {
                    ImportedWorkout(
                        id: $0.id, type: $0.type, startDate: $0.startDate,
                        durationMinutes: $0.durationMinutes, calories: $0.calories,
                        averageHeartRate: $0.averageHeartRate, maxHeartRate: $0.maxHeartRate,
                        distanceMiles: $0.distanceMiles
                    )
                }
        }()

        autoWSL = WSLAutoEvaluator.evaluate(
            WSLAutoEvaluator.Input(
                profile: playerProfileStore.profile,
                healthProfile: profile,
                settingsAge: settings.chronologicalAge,
                settingsSex: settings.biologicalSex,
                settingsHeightCm: settings.heightCm,
                settingsWeightKg: settings.weightKg,
                dailyHistory: dailyHistory,
                workouts: recentWorkouts + logged,
                liftSets: liftSets
            )
        )
    }
}
