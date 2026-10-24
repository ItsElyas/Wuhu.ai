import SwiftUI
import SwiftData

struct PartDetailSheet: View {
    var part: BodyPart
    var record: BodyPartStatusRecord?
    var recentWorkouts: [WorkoutRecord]
    var onSave: (BodyStatus, Int, String?) -> Void

    @State private var status: BodyStatus
    @State private var severity: Int
    @State private var note: String
    @Environment(\.dismiss) private var dismiss

    init(
        part: BodyPart,
        record: BodyPartStatusRecord?,
        recentWorkouts: [WorkoutRecord],
        onSave: @escaping (BodyStatus, Int, String?) -> Void
    ) {
        self.part = part
        self.record = record
        self.recentWorkouts = recentWorkouts
        self.onSave = onSave
        _status = State(initialValue: record?.status ?? .healthy)
        _severity = State(initialValue: record?.severity ?? 1)
        _note = State(initialValue: record?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(part.displayName, systemImage: part.symbolName)
                        .font(AppTypography.headline)
                    if let record {
                        Text("Current: \(record.status.rawValue.capitalized)")
                            .foregroundStyle(.secondary)
                        Text("Started \(record.startedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        Text("Healthy").tag(BodyStatus.healthy)
                        Text("Sore").tag(BodyStatus.sore)
                        Text("Injured").tag(BodyStatus.injured)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Body part status")

                    if status != .healthy {
                        VStack(alignment: .leading) {
                            Text("Severity \(severity)")
                            Slider(value: Binding(
                                get: { Double(severity) },
                                set: { severity = Int($0.rounded()) }
                            ), in: 1...5, step: 1)
                        }
                        TextField("Note (optional)", text: $note, axis: .vertical)
                    }
                }

                if status == .injured {
                    healingSection
                }

                if shouldShowClinicianNote {
                    Section {
                        Text("This area has been marked injured for a while or at high severity. Consider seeing a clinician or physical therapist. Tracking aid only — not medical advice.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !recentWorkouts.isEmpty {
                    Section("Recent workouts for this part") {
                        ForEach(recentWorkouts.prefix(5)) { workout in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(workout.type.capitalized)
                                Text(workout.startDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Body part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(status, severity, trimmed.isEmpty ? nil : trimmed)
                        dismiss()
                    }
                }
            }
        }
    }

    private var healingSection: some View {
        healingSectionContent(
            HealingRecommendations.recommendation(for: part, severity: severity)
        )
    }

    private func healingSectionContent(_ recommendation: HealingRecommendation) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label("How to heal", systemImage: "cross.case.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.injuredRed)

                Text(recommendation.summary)
                    .font(AppTypography.body)

                ForEach(recommendation.tips) { tip in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(AppTypography.headline)
                        Text(tip.detail)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }

                Text(recommendation.seekCareWhen)
                    .font(AppTypography.caption)
                    .foregroundStyle(.orange)

                Text(HealingRecommendations.disclaimer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Recovery tips")
        }
    }

    private var shouldShowClinicianNote: Bool {
        guard status == .injured else { return false }
        if severity >= 4 { return true }
        if let record, record.daysSinceStart >= 7 { return true }
        return false
    }
}

#Preview {
    PartDetailSheet(
        part: .rightKnee,
        record: BodyPartStatusRecord(part: .rightKnee, status: .injured, severity: 2),
        recentWorkouts: [],
        onSave: { _, _, _ in }
    )
}
