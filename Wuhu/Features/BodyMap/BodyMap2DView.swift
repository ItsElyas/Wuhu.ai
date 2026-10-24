import SwiftUI

/// Accessible SVG-style front/back body with tappable regions. Primary path when 3D is unavailable.
struct BodyMap2DView: View {
    var showFront: Bool
    var statusForPart: (BodyPart) -> (BodyStatus, Double)
    var weeklyLoadForPart: ((BodyPart) -> Double)?
    var heatMode: Bool
    var onSelect: (BodyPart) -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                ForEach(regions(width: w, height: h), id: \.part) { region in
                    let status = statusForPart(region.part)
                    let fill: Color = {
                        if heatMode, let load = weeklyLoadForPart?(region.part), load > 0 {
                            return Color.orange.opacity(min(0.85, 0.2 + load * 0.25))
                        }
                        if status.0 == .healthy {
                            return AppColors.skinTone.opacity(0.85)
                        }
                        return AppColors.bodyStatusColor(status: status.0, intensity: status.1)
                    }()

                    RoundedRectangle(cornerRadius: region.cornerRadius, style: .continuous)
                        .fill(fill)
                        .overlay {
                            if status.0 == .injured {
                                Image(systemName: "cross.case.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                            } else if status.0 == .sore || status.0 == .worked {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.black.opacity(0.55))
                            }
                        }
                        .frame(width: region.rect.width, height: region.rect.height)
                        .position(x: region.rect.midX, y: region.rect.midY)
                        .onTapGesture { onSelect(region.part) }
                        .accessibilityElement()
                        .accessibilityLabel("\(region.part.displayName), \(status.0.rawValue)")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint(status.0 == .injured ? "Opens healing recommendations" : "Opens status details")
                }
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(0.45, contentMode: .fit)
    }

    private struct Region {
        var part: BodyPart
        var rect: CGRect
        var cornerRadius: CGFloat
    }

    private func regions(width: CGFloat, height: CGFloat) -> [Region] {
        let cx = width / 2
        func r(_ part: BodyPart, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat = 8) -> Region {
            Region(part: part, rect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius)
        }

        if showFront {
            return [
                r(.head, cx - 28, 8, 56, 56, 28),
                r(.neck, cx - 16, 64, 32, 24),
                r(.leftShoulder, cx - 78, 88, 40, 28),
                r(.rightShoulder, cx + 38, 88, 40, 28),
                r(.chest, cx - 40, 100, 80, 48),
                r(.abs, cx - 34, 150, 68, 56),
                r(.leftBicep, cx - 92, 118, 28, 44),
                r(.rightBicep, cx + 64, 118, 28, 44),
                r(.leftForearm, cx - 96, 164, 26, 48),
                r(.rightForearm, cx + 70, 164, 26, 48),
                r(.leftHand, cx - 98, 214, 28, 24, 10),
                r(.rightHand, cx + 70, 214, 28, 24, 10),
                r(.leftHip, cx - 42, 208, 36, 28),
                r(.rightHip, cx + 6, 208, 36, 28),
                r(.leftQuad, cx - 44, 238, 38, 70),
                r(.rightQuad, cx + 6, 238, 38, 70),
                r(.leftKnee, cx - 40, 310, 30, 24),
                r(.rightKnee, cx + 10, 310, 30, 24),
                r(.leftCalf, cx - 40, 336, 30, 56),
                r(.rightCalf, cx + 10, 336, 30, 56),
                r(.leftAnkle, cx - 36, 394, 24, 18),
                r(.rightAnkle, cx + 12, 394, 24, 18),
                r(.leftFoot, cx - 40, 414, 32, 18, 6),
                r(.rightFoot, cx + 8, 414, 32, 18, 6),
            ]
        } else {
            return [
                r(.head, cx - 28, 8, 56, 56, 28),
                r(.neck, cx - 16, 64, 32, 24),
                r(.leftShoulder, cx + 38, 88, 40, 28),
                r(.rightShoulder, cx - 78, 88, 40, 28),
                r(.upperBack, cx - 40, 100, 80, 48),
                r(.lowerBack, cx - 34, 150, 68, 40),
                r(.glutes, cx - 40, 192, 80, 36),
                r(.leftTricep, cx + 64, 118, 28, 44),
                r(.rightTricep, cx - 92, 118, 28, 44),
                r(.leftForearm, cx + 70, 164, 26, 48),
                r(.rightForearm, cx - 96, 164, 26, 48),
                r(.leftHand, cx + 70, 214, 28, 24, 10),
                r(.rightHand, cx - 98, 214, 28, 24, 10),
                r(.leftHamstring, cx + 6, 238, 38, 70),
                r(.rightHamstring, cx - 44, 238, 38, 70),
                r(.leftKnee, cx + 10, 310, 30, 24),
                r(.rightKnee, cx - 40, 310, 30, 24),
                r(.leftCalf, cx + 10, 336, 30, 56),
                r(.rightCalf, cx - 40, 336, 30, 56),
                r(.leftAnkle, cx + 12, 394, 24, 18),
                r(.rightAnkle, cx - 36, 394, 24, 18),
                r(.leftFoot, cx + 8, 414, 32, 18, 6),
                r(.rightFoot, cx - 40, 414, 32, 18, 6),
            ]
        }
    }
}

#Preview {
    BodyMap2DView(
        showFront: true,
        statusForPart: { part in
            if part == .rightKnee { return (.injured, 1) }
            if part == .leftQuad { return (.sore, 0.8) }
            return (.healthy, 0)
        },
        weeklyLoadForPart: nil,
        heatMode: false,
        onSelect: { _ in }
    )
    .padding()
}
