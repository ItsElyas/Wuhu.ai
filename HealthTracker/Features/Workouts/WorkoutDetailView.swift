import SwiftUI

struct WorkoutDetailView: View {
    var workout: WorkoutRecord

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Type", value: workout.type.capitalized)
                LabeledContent("Duration", value: "\(Int(workout.durationMinutes)) min")
                LabeledContent("Intensity", value: workout.workoutIntensity.rawValue.capitalized)
                if let calories = workout.calories {
                    LabeledContent("Calories", value: "\(Int(calories)) kcal")
                }
                if let hr = workout.averageHeartRate {
                    LabeledContent("Avg HR", value: "\(Int(hr)) bpm")
                }
                LabeledContent("Source", value: workout.source == .healthKit ? "Apple Health" : "Manual")
                LabeledContent("Started", value: workout.startDate.formatted(date: .abbreviated, time: .shortened))
            }

            if !workout.musclesWorked.isEmpty {
                Section("Muscles worked") {
                    ForEach(workout.musclesWorked) { part in
                        Label(part.displayName, systemImage: part.symbolName)
                    }
                }
            }

            if let notes = workout.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle(workout.type.capitalized)
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(
            workout: WorkoutRecord(type: "running", startDate: .now, durationMinutes: 35, calories: 380, averageHeartRate: 152)
        )
    }
}
