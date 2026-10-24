import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let systemImage: String
    let accent: Color
    var accessibilityValue: String? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(AppTypography.metricValue)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue ?? [value, subtitle].compactMap { $0 }.joined(separator: ", "))
    }
}

#Preview {
    MetricCard(
        title: "Steps",
        value: "6,120",
        subtitle: "Goal 10,000",
        systemImage: "figure.walk",
        accent: AppColors.steps
    )
    .padding()
}
