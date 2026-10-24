import SwiftUI

struct GlassCard: ViewModifier {
    var radius: CGFloat = LayoutMetrics.cardRadius
    var fill: Color = AppColors.cardFill
    var shadowed: Bool = true

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppColors.cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(shadowed ? 0.06 : 0), radius: shadowed ? 24 : 0, y: shadowed ? 8 : 0)
    }
}

extension View {
    func glassCard(
        radius: CGFloat = LayoutMetrics.cardRadius,
        fill: Color = AppColors.cardFill,
        shadowed: Bool = true
    ) -> some View {
        modifier(GlassCard(radius: radius, fill: fill, shadowed: shadowed))
    }
}
