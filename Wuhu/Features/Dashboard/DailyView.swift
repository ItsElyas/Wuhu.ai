import SwiftUI

struct DailyView: View {
    var stats: DailyStats?
    var stepGoal: Int
    var onSelect: (DashboardMetric) -> Void

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today", subtitle: "Tap a card for details")

            Button { onSelect(.steps) } label: {
                HStack {
                    MetricCard(
                        title: "Steps",
                        value: stats?.steps.map { $0.formatted() } ?? "—",
                        subtitle: "Goal \(stepGoal.formatted())",
                        systemImage: "figure.walk",
                        accent: AppColors.steps
                    )
                    RingView(progress: stepProgress)
                        .frame(width: 56, height: 56)
                        .padding(.trailing, 12)
                }
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button { onSelect(.heartRate) } label: {
                MetricCard(
                    title: "Heart Rate",
                    value: heartValue,
                    subtitle: "Resting · latest",
                    systemImage: "heart.fill",
                    accent: AppColors.heart
                )
            }
            .buttonStyle(.plain)

            Button { onSelect(.sleep) } label: {
                VStack(alignment: .leading, spacing: 10) {
                    MetricCard(
                        title: "Sleep",
                        value: sleepValue,
                        subtitle: "Last night",
                        systemImage: "moon.zzz.fill",
                        accent: AppColors.sleep
                    )
                    if let sleep = stats?.sleep {
                        SleepStageBar(sleep: sleep)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                }
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button { onSelect(.calories) } label: {
                MetricCard(
                    title: "Calories",
                    value: calorieValue,
                    subtitle: "Active · resting",
                    systemImage: "flame.fill",
                    accent: AppColors.calories
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var stepProgress: Double {
        guard let steps = stats?.steps, stepGoal > 0 else { return 0 }
        return Double(steps) / Double(stepGoal)
    }

    private var heartValue: String {
        let resting = stats?.restingHeartRate.map { "\(Int($0))" } ?? "—"
        let latest = stats?.latestHeartRate.map { "\(Int($0))" } ?? "—"
        return "\(resting) · \(latest) bpm"
    }

    private var sleepValue: String {
        guard let hours = stats?.sleep?.totalHours else { return "—" }
        return String(format: "%.1f hr", hours)
    }

    private var calorieValue: String {
        let active = stats?.activeCalories.map { "\(Int($0))" } ?? "—"
        let resting = stats?.restingCalories.map { "\(Int($0))" } ?? "—"
        return "\(active) · \(resting) kcal"
    }
}

struct SleepStageBar: View {
    var sleep: SleepSummary

    var body: some View {
        GeometryReader { geo in
            let total = max(
                0.1,
                (sleep.deepHours ?? 0) + (sleep.remHours ?? 0) + (sleep.coreHours ?? 0) + (sleep.awakeHours ?? 0)
            )
            HStack(spacing: 2) {
                stage(sleep.deepHours, color: .indigo, width: geo.size.width, total: total, label: "Deep")
                stage(sleep.remHours, color: .purple, width: geo.size.width, total: total, label: "REM")
                stage(sleep.coreHours, color: .blue, width: geo.size.width, total: total, label: "Core")
                stage(sleep.awakeHours, color: .gray, width: geo.size.width, total: total, label: "Awake")
            }
        }
        .frame(height: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sleep stages")
        .accessibilityValue(stageSummary)
    }

    private var stageSummary: String {
        [
            sleep.deepHours.map { String(format: "Deep %.1f h", $0) },
            sleep.remHours.map { String(format: "REM %.1f h", $0) },
            sleep.coreHours.map { String(format: "Core %.1f h", $0) },
        ].compactMap { $0 }.joined(separator: ", ")
    }

    @ViewBuilder
    private func stage(_ hours: Double?, color: Color, width: CGFloat, total: Double, label: String) -> some View {
        let value = hours ?? 0
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: max(0, width * CGFloat(value / total)))
            .accessibilityLabel(label)
    }
}

#Preview {
    DailyView(
        stats: DailyStats(
            date: .now,
            steps: 6120,
            activeCalories: 410,
            restingCalories: 1780,
            restingHeartRate: 58,
            latestHeartRate: 72,
            sleep: SleepSummary(totalHours: 7.2, deepHours: 1.1, remHours: 1.6, coreHours: 4.5, awakeHours: 0.5)
        ),
        stepGoal: 10_000,
        onSelect: { _ in }
    )
    .padding()
}
