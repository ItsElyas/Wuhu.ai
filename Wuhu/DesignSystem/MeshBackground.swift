import SwiftUI

/// Fixed home backdrop. Light mesh matches `docs/design/home-reference.png`.
struct MeshBackground: View {
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: [
                Color(hex: 0xFDFBF8), Color(hex: 0xF1F6FA), Color(hex: 0xB7D9F3),
                Color(hex: 0xFDFBF8), Color(hex: 0xFBF6F7), Color(hex: 0xF4D3E3),
                Color(hex: 0xE98A70), Color(hex: 0xE88CBD), Color(hex: 0xC6B4EA)
            ]
        )
        .ignoresSafeArea()
    }
}

#Preview {
    MeshBackground()
}
