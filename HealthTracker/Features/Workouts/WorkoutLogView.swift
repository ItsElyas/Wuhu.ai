import SwiftUI
import SwiftData

struct WorkoutLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var type: String = "running"
    @State private var durationMinutes: Double = 30
    @State private var intensity: WorkoutIntensity = .moderate
    @State private var calories: String = ""
    @State private var averageHR: String = ""
    @State private var notes: String = ""
    @State private var selectedParts: Set<BodyPart> = []
    @State private var startDate: Date = .now

    private let types = ["running", "walking", "cycling", "swimming", "strength", "hiit", "yoga", "rowing", "other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    .onChange(of: type) { _, newValue in
                        selectedParts = Set(WorkoutLoadMapper.parts(forWorkoutType: newValue))
                    }

                    DatePicker("Start", selection: $startDate)

                    Stepper("Duration: \(Int(durationMinutes)) min", value: $durationMinutes, in: 5...240, step: 5)

                    Picker("Intensity", selection: $intensity) {
                        ForEach(WorkoutIntensity.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }

                    TextField("Calories (optional)", text: $calories)
                        .keyboardType(.decimalPad)
                    TextField("Avg heart rate (optional)", text: $averageHR)
                        .keyboardType(.decimalPad)
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section("Muscles worked") {
                    ForEach(BodyPart.allCases) { part in
                        Toggle(part.displayName, isOn: Binding(
                            get: { selectedParts.contains(part) },
                            set: { isOn in
                                if isOn { selectedParts.insert(part) } else { selectedParts.remove(part) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Add Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                selectedParts = Set(WorkoutLoadMapper.parts(forWorkoutType: type))
            }
        }
    }

    private func save() {
        let workout = WorkoutRecord(
            type: type,
            startDate: startDate,
            durationMinutes: durationMinutes,
            calories: Double(calories),
            averageHeartRate: Double(averageHR),
            intensity: intensity,
            notes: notes.isEmpty ? nil : notes,
            source: .manual,
            musclesWorked: Array(selectedParts)
        )
        modelContext.insert(workout)

        var records = (try? modelContext.fetch(FetchDescriptor<BodyPartStatusRecord>())) ?? []
        WorkoutLoadMapper.applyWorkoutLoad(
            to: &records,
            parts: Array(selectedParts),
            durationMinutes: durationMinutes,
            averageHeartRate: Double(averageHR)
        )
        for record in records where record.modelContext == nil {
            modelContext.insert(record)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    WorkoutLogView()
        .modelContainer(for: [WorkoutRecord.self, BodyPartStatusRecord.self], inMemory: true)
}
