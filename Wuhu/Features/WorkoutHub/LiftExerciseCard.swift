import SwiftUI
import SwiftData

/// One exercise in an active lifting session: target line plus editable set rows.
struct LiftExerciseCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var exercise: HubExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(AppTypography.cardLabel)
                        .foregroundStyle(AppColors.ink)
                    if let target = exercise.targetLine {
                        Text("Target: \(target)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer()
            }

            HStack {
                columnHeader("SET", width: 36)
                columnHeader("LBS", width: nil)
                columnHeader("REPS", width: nil)
                columnHeader("DONE", width: 44)
            }

            ForEach(exercise.sortedSets) { set in
                LiftSetRow(set: set)
            }

            HStack {
                Button {
                    HubSessionService.addSet(to: exercise, in: modelContext)
                } label: {
                    Label("Add Set", systemImage: "plus")
                }
                Spacer()
                if let last = exercise.sortedSets.last, exercise.sets.count > 1 {
                    Button(role: .destructive) {
                        exercise.sets.removeAll { $0.id == last.id }
                        modelContext.delete(last)
                        try? modelContext.save()
                    } label: {
                        Label("Remove Set", systemImage: "minus")
                    }
                }
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .tint(AppColors.accent)
        }
        .padding(LayoutMetrics.cardPadding)
        .glassCard(radius: 16, shadowed: false)
    }

    private func columnHeader(_ title: String, width: CGFloat?) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AppColors.textSecondary)
            .frame(width: width)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .accessibilityHidden(true)
    }
}

/// Editable weight / reps / done for one set. Invalid input is flagged and not saved.
struct LiftSetRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var set: HubSetLog

    @State private var weightText = ""
    @State private var repsText = ""

    private var weightInvalid: Bool {
        !set.usesBodyweight && !weightText.isEmpty && HubFormat.parseNumber(weightText, in: HubFormat.weightRange) == nil
    }

    private var repsInvalid: Bool {
        !repsText.isEmpty && Int(repsText).map { HubFormat.repsRange.contains($0) } != true
    }

    var body: some View {
        HStack {
            Text("\(set.setNumber)")
                .font(.callout.monospacedDigit())
                .frame(width: 36)
            TextField(set.usesBodyweight ? "BW" : "lbs", text: $weightText)
                .keyboardType(.decimalPad)
                .disabled(set.usesBodyweight)
                .modifier(HubFieldStyle(invalid: weightInvalid))
                .accessibilityLabel("Set \(set.setNumber) weight in pounds")
            TextField("reps", text: $repsText)
                .keyboardType(.numberPad)
                .modifier(HubFieldStyle(invalid: repsInvalid))
                .accessibilityLabel("Set \(set.setNumber) reps")
            Button {
                set.isCompleted.toggle()
                try? modelContext.save()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? AppColors.accent : AppColors.textSecondary)
            }
            .frame(width: 44)
            .accessibilityLabel(set.isCompleted ? "Set \(set.setNumber) done" : "Mark set \(set.setNumber) done")
        }
        .onAppear {
            weightText = set.usesBodyweight ? "" : set.weightLbs.map(HubFormat.weight) ?? ""
            repsText = "\(set.reps)"
        }
        .onChange(of: weightText) { _, text in
            if text.isEmpty {
                set.weightLbs = nil
            } else if let value = HubFormat.parseNumber(text, in: HubFormat.weightRange) {
                set.weightLbs = value
            } else { return }
            try? modelContext.save()
        }
        .onChange(of: repsText) { _, text in
            guard let reps = Int(text), HubFormat.repsRange.contains(reps) else { return }
            set.reps = reps
            try? modelContext.save()
        }
    }
}

/// Rounded numeric field; red outline when the value is out of range.
struct HubFieldStyle: ViewModifier {
    var invalid: Bool

    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .font(.callout.monospacedDigit())
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(invalid ? Color.red : AppColors.cardStroke, lineWidth: invalid ? 1.5 : 1)
            )
    }
}
