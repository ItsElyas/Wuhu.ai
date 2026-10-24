import Foundation

/// Turns a `WorkoutDatabaseEngine.ExercisePrescription` into loggable Workout Hub items.
/// Pure and deterministic so it is easy to test.
enum HubRegimenBuilder {

    struct LiftItem: Equatable, Sendable {
        var name: String
        var sets: Int
        var reps: String
        var intensity: String
    }

    struct RunItem: Equatable, Sendable {
        var label: String
        var target: String
        /// Pre-filled distance when the target states one (e.g. "1 Mile").
        var plannedMiles: Double?
    }

    struct Regimen: Equatable, Sendable {
        var kind: HubWorkoutKind
        var title: String
        var focus: String
        var cue: String
        var isRestDay: Bool
        var lifts: [LiftItem]
        var runs: [RunItem]
    }

    /// Splits combined blocks ("A + B" with reps "3 + 3") into one item per movement.
    static func regimen(
        from prescription: WorkoutDatabaseEngine.ExercisePrescription,
        kind: HubWorkoutKind
    ) -> Regimen {
        let isRest = prescription.sessionType == .activeRecovery || prescription.sessionType == .completeRest
        let names = split(prescription.exercise)
        let reps = split(prescription.reps)
        let title = "\(prescription.dayOfWeek.rawValue) · \(prescription.sessionFocus)"

        switch kind {
        case .lifting:
            let lifts = names.enumerated().map { index, name in
                LiftItem(
                    name: name,
                    sets: max(1, prescription.sets),
                    reps: reps.count == names.count ? reps[index] : prescription.reps,
                    intensity: prescription.intensity
                )
            }
            return Regimen(kind: kind, title: title, focus: prescription.sessionFocus, cue: prescription.cue,
                           isRestDay: isRest, lifts: isRest ? [] : lifts, runs: [])

        case .running:
            var runs: [RunItem] = []
            for (index, name) in names.enumerated() {
                let target = reps.count == names.count ? reps[index] : (index == 0 ? prescription.reps : "As prescribed")
                // The lead block repeats `sets` times (e.g. 4 × 1 Mile); extra blocks are one segment.
                let count = index == 0 ? max(1, prescription.sets) : 1
                for rep in 1...count {
                    let label = count > 1 ? "\(name) · Rep \(rep) of \(count)" : name
                    runs.append(RunItem(
                        label: label,
                        target: "\(target) · \(prescription.intensity)",
                        plannedMiles: plannedMiles(from: target)
                    ))
                }
            }
            return Regimen(kind: kind, title: title, focus: prescription.sessionFocus, cue: prescription.cue,
                           isRestDay: isRest, lifts: [], runs: isRest ? [] : runs)
        }
    }

    /// Fallback when there is no prescription or the user picks "Free workout".
    static func freeWorkout(kind: HubWorkoutKind) -> Regimen {
        switch kind {
        case .running:
            return Regimen(kind: kind, title: "Free Run", focus: "Free run", cue: "Log distance and time; pace is calculated.",
                           isRestDay: false, lifts: [], runs: [RunItem(label: "Run", target: "Any distance", plannedMiles: nil)])
        case .lifting:
            return Regimen(kind: kind, title: "Free Lift", focus: "Free lift", cue: "Add exercises and log each set.",
                           isRestDay: false, lifts: [], runs: [])
        }
    }

    static func split(_ text: String) -> [String] {
        text.components(separatedBy: " + ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Reads "1 Mile", "3 miles", "400m", "5K" targets into miles; time targets return `nil`.
    static func plannedMiles(from target: String) -> Double? {
        let lower = target.lowercased()
        let number = Double(lower.prefix { "0123456789.".contains($0) }) ?? (lower.hasPrefix("mile") ? 1 : nil)
        guard let number else { return nil }
        if lower.contains("mile") { return number }
        if lower.contains("km") || lower.hasSuffix("k") { return number * 0.621371 }
        if lower.contains("m") && !lower.contains("min") { return number / 1609.344 }
        return nil
    }
}
