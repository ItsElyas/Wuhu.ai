import SwiftUI
import UIKit

struct WSLScoreCard: View {
    var presentation: WSLScorePresentation
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt")
                        .font(.system(size: 14, weight: .medium))
                    Text("WSL Score")
                        .font(AppTypography.cardLabel)
                }
                .foregroundStyle(AppColors.textSecondary)
                Text(presentation.headline)
                    .font(AppTypography.bigValue)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if let detail = presentation.detail {
                    Text(detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(LayoutMetrics.cardPadding)
            .frame(maxWidth: .infinity, minHeight: LayoutMetrics.topCardHeight, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("WSL Score, \(presentation.headline)")
        .accessibilityAddTraits(.isButton)
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }
            }
    }
}

#Preview("Mid tier") {
    WSLScoreCard(presentation: WSLScorePresentation(headline: "Mid Tier Player", detail: "3.20 / 6.0"), onTap: {})
        .frame(width: 172)
        .padding()
        .background(MeshBackground())
}

#Preview("Collecting") {
    WSLScoreCard(presentation: .collectingProfile, onTap: {})
        .frame(width: 172)
        .padding()
        .background(MeshBackground())
}

#Preview("Large type") {
    WSLScoreCard(presentation: WSLScorePresentation(headline: "GOAT Lite", detail: "5.10 / 6.0"), onTap: {})
        .padding()
        .dynamicTypeSize(.accessibility2)
}
