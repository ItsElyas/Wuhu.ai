import SwiftUI
import Charts

struct WeeklyView: View {
    var weekly: WeeklyStats?
    var onSelect: (DashboardMetric) -> Void

    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "This week", subtitle: weekSubtitle)

            chartCard(
                title: "Steps",
                accent: AppColors.steps,
                metric: .steps,
                average: weekly?.averageSteps.map { "Avg \(Int($0).formatted())" },
                change: weekly?.stepsChangePercent
            ) {
                Chart(weekly?.days ?? []) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Steps", day.steps ?? 0)
                    )
                    .foregroundStyle(AppColors.steps)
                }
                .frame(height: 140)
                .accessibilityLabel("Steps chart")
            }

            chartCard(
                title: "Heart Rate",
                accent: AppColors.heart,
                metric: .heartRate,
                average: weekly?.averageRestingHeartRate.map { String(format: "Avg %.0f bpm", $0) },
                change: weekly?.restingHeartRateChangePercent
            ) {
                Chart(weekly?.days ?? []) { day in
                    LineMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("RHR", day.restingHeartRate ?? 0)
                    )
                    .foregroundStyle(AppColors.heart)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 140)
                .accessibilityLabel("Resting heart rate chart")
            }

            chartCard(
                title: "Sleep",
                accent: AppColors.sleep,
                metric: .sleep,
                average: weekly?.averageSleepHours.map { String(format: "Avg %.1f hr", $0) },
                change: weekly?.sleepChangePercent
            ) {
                Chart(weekly?.days ?? []) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Hours", day.sleep?.totalHours ?? 0)
                    )
                    .foregroundStyle(AppColors.sleep)
                }
                .frame(height: 140)
                .accessibilityLabel("Sleep chart")
            }

            chartCard(
                title: "Calories",
                accent: AppColors.calories,
                metric: .calories,
                average: weekly?.averageActiveCalories.map { "Avg \(Int($0)) kcal" },
                change: weekly?.activeCaloriesChangePercent
            ) {
                Chart(weekly?.days ?? []) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Active", day.activeCalories ?? 0)
                    )
                    .foregroundStyle(AppColors.calories)
                }
                .frame(height: 140)
                .accessibilityLabel("Active calories chart")
            }
        }
    }

    private var weekSubtitle: String {
        if let minutes = weekly?.averageWorkoutMinutes {
            return String(format: "Avg workout %.0f min/day", minutes)
        }
        return "7-day averages and week-over-week change"
    }

    private func chartCard<Content: View>(
        title: String,
        accent: Color,
        metric: DashboardMetric,
        average: String?,
        change: Double?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button { onSelect(metric) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundStyle(accent)
                    Spacer()
                    if let change {
                        Text(String(format: "%+.0f%%", change))
                            .font(AppTypography.caption)
                            .foregroundStyle(change >= 0 ? .green : .secondary)
                    }
                }
                if let average {
                    Text(average)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                content()
            }
            .padding(16)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WeeklyView(weekly: nil, onSelect: { _ in })
        .padding()
}
