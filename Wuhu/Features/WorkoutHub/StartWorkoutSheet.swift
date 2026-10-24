import SwiftUI

/// Step 1: Running or Lifting. Step 2: pick the regimen (today's plan by default) and start.
struct StartWorkoutSheet: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss

    var onStart: (HubRegimenBuilder.Regimen) -> Void

    @State private var kind: HubWorkoutKind?
    /// `nil` = free workout; otherwise the prescription's day.
    @State private var day: AthleteOnboardingEngine.DayOfWeek? = .from(date: .now)

    var body: some View {
        NavigationStack {
            Group {
                if let kind {
                    regimenStep(kind)
                } else {
                    kindStep
                }
            }
            .navigationTitle(kind == nil ? "Start Workout" : kind?.title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if kind != nil {
                        Button("Back") { kind = nil }
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Step 1

    private var kindStep: some View {
        VStack(spacing: 16) {
            Text("What are you training?")
                .font(AppTypography.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(HubWorkoutKind.allCases) { option in
                Button {
                    kind = option
                    day = .from(date: .now)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: option.symbol)
                            .font(.largeTitle)
                            .frame(width: 56)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title).font(AppTypography.headline)
                            Text(option == .running ? "Log miles, time, and pace" : "Log weight, reps, and sets")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    .foregroundStyle(AppColors.ink)
                    .padding(LayoutMetrics.cardPadding)
                    .frame(maxWidth: .infinity)
                    .glassCard()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.title) workout")
            }
            Spacer()
        }
        .padding()
        .background(MeshBackground())
    }

    // MARK: - Step 2

    private func prescription(for kind: HubWorkoutKind, day: AthleteOnboardingEngine.DayOfWeek) -> WorkoutDatabaseEngine.ExercisePrescription? {
        app.workoutDatabaseEngine.fetchWorkouts(for: kind.sport).first { $0.dayOfWeek == day }
    }

    private func regimen(for kind: HubWorkoutKind) -> HubRegimenBuilder.Regimen {
        guard let day, let prescription = prescription(for: kind, day: day) else {
            return HubRegimenBuilder.freeWorkout(kind: kind)
        }
        return HubRegimenBuilder.regimen(from: prescription, kind: kind)
    }

    private func regimenStep(_ kind: HubWorkoutKind) -> some View {
        let regimen = regimen(for: kind)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Regimen", selection: $day) {
                    ForEach(AthleteOnboardingEngine.DayOfWeek.allCases, id: \.self) { option in
                        Text(option == .from(date: .now) ? "Today (\(option.rawValue))" : option.rawValue)
                            .tag(Optional(option))
                    }
                    Text("Free workout").tag(AthleteOnboardingEngine.DayOfWeek?.none)
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Choose regimen day")

                RegimenPreview(regimen: regimen)

                if regimen.isRestDay {
                    Text("This is a recovery day in your plan. You can still start it to log a free \(kind.title.lowercased()) session.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Button {
                    onStart(regimen.isRestDay ? HubRegimenBuilder.freeWorkout(kind: kind) : regimen)
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                        .font(AppTypography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accent)
            }
            .padding()
        }
        .background(MeshBackground())
    }
}

/// Read-only list of what the regimen asks for.
struct RegimenPreview: View {
    let regimen: HubRegimenBuilder.Regimen

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(regimen.focus)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.ink)
            Text(regimen.cue)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Divider()
            ForEach(Array(regimen.lifts.enumerated()), id: \.offset) { _, lift in
                row(lift.name, "\(lift.sets) × \(lift.reps) · \(lift.intensity)")
            }
            ForEach(Array(regimen.runs.enumerated()), id: \.offset) { _, run in
                row(run.label, run.target)
            }
            if regimen.lifts.isEmpty && regimen.runs.isEmpty {
                Text(regimen.kind == .lifting ? "Add exercises once you start." : "Add run segments once you start.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(LayoutMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func row(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppTypography.cardLabel).foregroundStyle(AppColors.ink)
            Text(detail).font(AppTypography.caption).foregroundStyle(AppColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}
