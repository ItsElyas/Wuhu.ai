import SwiftUI

struct SleepCard: View {
    var total: String
    var deep: String?
    var spoken: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "moon")
                        .font(.system(size: 14, weight: .medium))
                    Text("Sleep")
                        .font(AppTypography.cardLabel)
                }
                .foregroundStyle(AppColors.textSecondary)
                Text(total)
                    .font(AppTypography.bigValue)
                    .foregroundStyle(AppColors.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(deep ?? "No sleep data")
                    .font(AppTypography.homeCaption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(LayoutMetrics.cardPadding)
            .frame(maxWidth: .infinity, minHeight: LayoutMetrics.topCardHeight, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Reference") {
    SleepCard(total: "7h 42m", deep: "Deep 1h 50m", spoken: "Sleep 7 hours 42 minutes", onTap: {})
        .frame(width: 172)
        .padding()
        .background(MeshBackground())
}

#Preview("Empty") {
    SleepCard(total: "--", deep: nil, spoken: "Sleep, no data", onTap: {})
        .frame(width: 172)
        .padding()
}

#Preview("Large type") {
    SleepCard(total: "7h 42m", deep: "Deep 1h 50m", spoken: "Sleep", onTap: {})
        .padding()
        .dynamicTypeSize(.accessibility2)
}

#Preview("SE") {
    SleepCard(total: "7h 42m", deep: "Deep 1h 50m", spoken: "Sleep", onTap: {})
        .frame(width: 150)
        .padding()
}
