import SwiftUI

struct WearAndTearCard: View {
    var state: HomeState
    var reduceMotion: Bool
    var stacked: Bool
    var onBody: () -> Void
    var onSteps: () -> Void
    var onCalories: () -> Void
    var onRecovery: () -> Void

    private var recommendation: DailyRecommendation? { state.recommendation }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wear & Tear")
                .font(AppTypography.homeTitle)
                .foregroundStyle(AppColors.ink)

            if stacked {
                VStack(spacing: 12) {
                    recommended
                    figureButton
                    pills
                }
            } else {
                HStack(alignment: .center, spacing: 0) {
                    recommended
                        .frame(maxWidth: .infinity, alignment: .leading)
                    figureButton
                        .padding(.leading, LayoutMetrics.figureLeadingGap)
                        .padding(.trailing, LayoutMetrics.figureTrailingGap)
                    pills
                        .frame(width: LayoutMetrics.pillColumnWidth)
                }
            }

            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 1)
                .padding(.top, 4)

            HStack(spacing: 16) {
                legend(AppColors.wearSlight, "Slight")
                legend(AppColors.wearHigh, "High")
                legend(AppColors.wearSevere, "Severe")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(LayoutMetrics.wearPadding)
        .frame(maxWidth: .infinity, minHeight: stacked ? nil : LayoutMetrics.wearHeight, alignment: .top)
        .glassCard(radius: LayoutMetrics.wearRadius, fill: AppColors.wearCardFill)
    }

    private var recommended: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recommended")
                .font(AppTypography.recommendedHeader)
                .foregroundStyle(AppColors.ink)
            row("Spec", recommendation?.focus ?? "--")
            row("Sleep", recommendation.map { HomeFormat.sleepTarget($0.sleepHours) } ?? "--")
            row("Workout", recommendation.map { HomeFormat.workoutTarget($0.workoutMinutes) } ?? "--")
            row("Cal", recommendation.map { HomeFormat.grouped($0.calories) } ?? "--")
            row("In", state.caloriesIn.map { HomeFormat.grouped($0) } ?? "--")
            if let note = state.nutritionNote {
                Text(note)
                    .font(AppTypography.backNote)
                    .foregroundStyle(AppColors.textTertiary)
                    .accessibilityLabel("Macros \(note)")
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.rowLabel)
                .foregroundStyle(AppColors.textTertiary)
            Spacer(minLength: 8)
            Text(value)
                .font(AppTypography.rowValue)
                .foregroundStyle(AppColors.ink)
        }
    }

    private var figureButton: some View {
        Button(action: onBody) {
            VStack(spacing: 2) {
                MiniBodyFigure(wear: state.wear, reduceMotion: reduceMotion)
                if backCount > 0 {
                    Text("+\(backCount) on back")
                        .font(AppTypography.backNote)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens body map")
    }

    private var backCount: Int {
        state.wear.keys.filter { MiniBodyLayout.backOnly.contains($0) && state.wear[$0] != .none }.count
    }

    private var pills: some View {
        VStack(spacing: LayoutMetrics.pillGap) {
            StatPill(
                title: "Steps",
                value: state.steps.map { HomeFormat.grouped($0) } ?? "--",
                systemImage: "shoeprints.fill",
                onTap: onSteps
            )
            StatPill(
                title: "Burned",
                value: state.caloriesBurned.map { HomeFormat.grouped($0) } ?? "--",
                systemImage: "flame",
                onTap: onCalories
            )
            StatPill(
                title: "Readiness",
                value: state.readinessPercent.map { "\($0)%" } ?? "--",
                systemImage: "heart.text.square",
                onTap: onRecovery
            )
        }
    }

    private func legend(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: LayoutMetrics.legendDot, height: LayoutMetrics.legendDot)
            Text(title)
                .font(AppTypography.homeCaption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Reference") {
    WearAndTearCard(
        state: HomeFixture.reference,
        reduceMotion: true,
        stacked: false,
        onBody: {}, onSteps: {}, onCalories: {}, onRecovery: {}
    )
    .padding()
    .background(MeshBackground())
}

#Preview("Empty") {
    WearAndTearCard(
        state: HomeFixture.empty,
        reduceMotion: true,
        stacked: false,
        onBody: {}, onSteps: {}, onCalories: {}, onRecovery: {}
    )
    .padding()
}

#Preview("Large type") {
    WearAndTearCard(
        state: HomeFixture.reference,
        reduceMotion: true,
        stacked: true,
        onBody: {}, onSteps: {}, onCalories: {}, onRecovery: {}
    )
    .padding()
    .dynamicTypeSize(.accessibility2)
}

#Preview("SE") {
    WearAndTearCard(
        state: HomeFixture.reference,
        reduceMotion: true,
        stacked: false,
        onBody: {}, onSteps: {}, onCalories: {}, onRecovery: {}
    )
    .frame(width: 320)
    .padding(8)
}
