import SwiftUI

struct NavRow: View {
    var title: String
    var leadingIcon: String?
    var trailingIcon: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let leadingIcon {
                    Image(systemName: leadingIcon)
                        .font(.system(size: 18, weight: .regular))
                        .padding(.leading, LayoutMetrics.navIconLeading - 16)
                }
                Text(title)
                    .font(AppTypography.homeTitle)
                Spacer(minLength: 0)
                Image(systemName: trailingIcon)
                    .font(.system(size: trailingIcon == "chevron.right" ? 14 : 20, weight: .semibold))
                    .padding(.trailing, LayoutMetrics.navTrailingInset - 16)
            }
            .foregroundStyle(AppColors.ink)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: LayoutMetrics.navHeight)
            .background(AppColors.navRowFill, in: Capsule())
            .overlay(Capsule().strokeBorder(AppColors.cardStroke, lineWidth: 1))
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 14) {
        NavRow(title: "Weekly Stats", leadingIcon: "chart.bar", trailingIcon: "chevron.right", onTap: {})
        NavRow(title: "Workout Hub", leadingIcon: nil, trailingIcon: "dumbbell", onTap: {})
    }
    .padding()
    .background(MeshBackground())
}
