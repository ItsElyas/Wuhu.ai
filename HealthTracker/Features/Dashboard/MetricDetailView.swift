import SwiftUI
import Charts

struct MetricDetailView: View {
    var metric: DashboardMetric
    var history: [DailyStats]

    var body: some View {
        ScrollView {
            Chart(history.suffix(14)) { day in
                switch metric {
                case .steps:
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Steps", day.steps ?? 0)
                    )
                    .foregroundStyle(AppColors.steps)
                case .heartRate:
                    LineMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("RHR", day.restingHeartRate ?? 0)
                    )
                    .foregroundStyle(AppColors.heart)
                case .sleep:
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Hours", day.sleep?.totalHours ?? 0)
                    )
                    .foregroundStyle(AppColors.sleep)
                case .calories:
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("kcal", day.activeCalories ?? 0)
                    )
                    .foregroundStyle(AppColors.calories)
                }
            }
            .frame(height: 260)
            .padding()
            .accessibilityLabel("\(metric.title) detail chart")
        }
        .navigationTitle(metric.title)
    }
}

#Preview {
    NavigationStack {
        MetricDetailView(metric: .steps, history: [])
    }
}
