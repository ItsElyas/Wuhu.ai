import Foundation

enum WorkoutPrescriptionLoader {
    static func loadFromBundle() -> [WorkoutDatabaseEngine.ExercisePrescription] {
        guard
            let url = Bundle.main.url(forResource: "workout_prescriptions", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            return WorkoutDatabaseEngine.Repository.buildWeeklyExerciseBank()
        }
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([WorkoutDatabaseEngine.ExercisePrescription].self, from: data),
           !decoded.isEmpty {
            return decoded
        }
        return WorkoutDatabaseEngine.Repository.buildWeeklyExerciseBank()
    }
}
