import SwiftUI

struct StatPill: View {
    var title: String
    var value: String
    var systemImage: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .medium))
                    Text(title)
                        .font(AppTypography.pillLabel)
                }
                .foregroundStyle(AppColors.textSecondary)
                Text(value)
                    .font(AppTypography.pillValue)
                    .foregroundStyle(AppColors.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .background(AppColors.pillFill, in: RoundedRectangle(cornerRadius: LayoutMetrics.pillRadius, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(value)")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack {
        StatPill(title: "Steps", value: "8,214", systemImage: "shoeprints.fill", onTap: {})
        StatPill(title: "Calories", value: "1,940", systemImage: "flame", onTap: {})
        StatPill(title: "Recovery", value: "74%", systemImage: "heart.text.square", onTap: {})
    }
    .frame(width: 120)
    .padding()
    .background(AppColors.wearCardFill)
}
