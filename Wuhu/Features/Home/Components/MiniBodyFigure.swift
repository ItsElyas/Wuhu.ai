import SwiftUI

/// Front-view silhouette. TODO: replace with final vector art in the asset catalog.
/// Original SwiftUI shapes only. Person's right side is drawn on the viewer's left.
struct MiniBodyFigure: View {
    var wear: [BodyPart: WearLevel]
    var reduceMotion: Bool
    @State private var shown = false

    var body: some View {
        ZStack {
            ForEach(Self.pieces, id: \.part) { piece in
                RoundedRectangle(cornerRadius: piece.radius, style: .continuous)
                    .fill(AppColors.bodyBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: piece.radius, style: .continuous)
                            .stroke(AppColors.bodyOutline, lineWidth: 0.5)
                    )
                    .overlay {
                        if let level = wear[piece.part], level != .none {
                            RoundedRectangle(cornerRadius: piece.radius, style: .continuous)
                                .fill(Self.color(level).opacity(shown || reduceMotion ? 0.95 : 0))
                        }
                    }
                    .frame(width: piece.size.width, height: piece.size.height)
                    .position(piece.center)
            }
        }
        .frame(width: LayoutMetrics.figureWidth, height: LayoutMetrics.figureHeight)
        .onAppear {
            if reduceMotion {
                shown = true
            } else {
                withAnimation(.easeOut(duration: 0.3)) { shown = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var spoken: String {
        let parts = wear
            .filter { $0.value != .none }
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($0.key.displayName) \($0.value.title)" }
        if parts.isEmpty { return "Wear and tear: no marked areas" }
        return "Wear and tear: " + parts.joined(separator: ", ")
    }

    static func color(_ level: WearLevel) -> Color {
        AppColors.wearColor(for: level)
    }

    private struct Piece: Identifiable {
        var part: BodyPart
        var center: CGPoint
        var size: CGSize
        var radius: CGFloat
        var id: BodyPart { part }
    }

    /// Coordinates inside a 68 x 128 canvas. `right*` parts use smaller x (viewer left).
    private static let pieces: [Piece] = [
        Piece(part: .head, center: CGPoint(x: 34, y: 10), size: CGSize(width: 16, height: 16), radius: 8),
        Piece(part: .neck, center: CGPoint(x: 34, y: 21), size: CGSize(width: 8, height: 6), radius: 2),
        Piece(part: .rightShoulder, center: CGPoint(x: 20, y: 28), size: CGSize(width: 14, height: 8), radius: 4),
        Piece(part: .leftShoulder, center: CGPoint(x: 48, y: 28), size: CGSize(width: 14, height: 8), radius: 4),
        Piece(part: .chest, center: CGPoint(x: 34, y: 36), size: CGSize(width: 22, height: 16), radius: 6),
        Piece(part: .abs, center: CGPoint(x: 34, y: 52), size: CGSize(width: 16, height: 14), radius: 4),
        Piece(part: .rightBicep, center: CGPoint(x: 12, y: 40), size: CGSize(width: 7, height: 16), radius: 3),
        Piece(part: .leftBicep, center: CGPoint(x: 56, y: 40), size: CGSize(width: 7, height: 16), radius: 3),
        Piece(part: .rightForearm, center: CGPoint(x: 8, y: 56), size: CGSize(width: 6, height: 14), radius: 3),
        Piece(part: .leftForearm, center: CGPoint(x: 60, y: 56), size: CGSize(width: 6, height: 14), radius: 3),
        Piece(part: .rightHand, center: CGPoint(x: 7, y: 68), size: CGSize(width: 6, height: 6), radius: 2),
        Piece(part: .leftHand, center: CGPoint(x: 61, y: 68), size: CGSize(width: 6, height: 6), radius: 2),
        Piece(part: .rightHip, center: CGPoint(x: 26, y: 64), size: CGSize(width: 12, height: 8), radius: 3),
        Piece(part: .leftHip, center: CGPoint(x: 42, y: 64), size: CGSize(width: 12, height: 8), radius: 3),
        Piece(part: .rightQuad, center: CGPoint(x: 26, y: 82), size: CGSize(width: 12, height: 22), radius: 5),
        Piece(part: .leftQuad, center: CGPoint(x: 42, y: 82), size: CGSize(width: 12, height: 22), radius: 5),
        Piece(part: .rightKnee, center: CGPoint(x: 26, y: 96), size: CGSize(width: 10, height: 8), radius: 3),
        Piece(part: .leftKnee, center: CGPoint(x: 42, y: 96), size: CGSize(width: 10, height: 8), radius: 3),
        Piece(part: .rightCalf, center: CGPoint(x: 26, y: 110), size: CGSize(width: 9, height: 16), radius: 4),
        Piece(part: .leftCalf, center: CGPoint(x: 42, y: 110), size: CGSize(width: 9, height: 16), radius: 4),
        Piece(part: .rightAnkle, center: CGPoint(x: 26, y: 120), size: CGSize(width: 8, height: 5), radius: 2),
        Piece(part: .leftAnkle, center: CGPoint(x: 42, y: 120), size: CGSize(width: 8, height: 5), radius: 2),
        Piece(part: .rightFoot, center: CGPoint(x: 24, y: 124), size: CGSize(width: 12, height: 4), radius: 2),
        Piece(part: .leftFoot, center: CGPoint(x: 44, y: 124), size: CGSize(width: 12, height: 4), radius: 2)
    ]
}

#Preview("Reference") {
    MiniBodyFigure(wear: HomeFixture.reference.wear, reduceMotion: true)
        .padding()
        .background(Color.white)
}

#Preview("Empty") {
    MiniBodyFigure(wear: [:], reduceMotion: true)
        .padding()
}
