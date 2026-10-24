import SwiftUI

struct WeeklyMetric: Identifiable {
    var id: String
    var title: String
    var value: String
    var systemImage: String
    var tintHex: UInt32
    var trend: String
    var trendSymbol: String
    var favorable: Bool
    var footnote: String

    var tint: Color { Color(hex: tintHex) }
}

struct WeeklyMetricCard: View {
    var metric: WeeklyMetric

    private var trendColor: Color {
        metric.favorable ? Color(hex: 0x1FA971) : AppColors.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: metric.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(metric.tint)
                .frame(width: 28, height: 28)
                .background(metric.tint.opacity(0.14), in: Circle())
            Text(metric.title)
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(metric.value)
                .font(AppTypography.weeklyValue)
                .foregroundStyle(AppColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 2) {
                Image(systemName: metric.trendSymbol)
                    .font(.system(size: 9, weight: .bold))
                Text(metric.trend)
                    .font(AppTypography.weeklyDelta)
            }
            .foregroundStyle(trendColor)
            Text(metric.footnote)
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .glassCard(radius: 22)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.title), \(metric.value), \(metric.trend) \(metric.footnote)")
    }
}
