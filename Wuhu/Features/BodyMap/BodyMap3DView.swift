import SwiftUI
import RealityKit
import UIKit

/// RealityKit body built from named primitive entities (or an optional body.usdz).
struct BodyMap3DView: View {
    var statusForPart: (BodyPart) -> (BodyStatus, Double)
    var onSelect: (BodyPart) -> Void

    @State private var yaw: Float = 0
    @State private var pitch: Float = 0
    @State private var zoom: Float = 1.1
    @State private var rootEntity: Entity?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RealityView { content in
            let root = await Self.loadBodyRoot()
            content.add(root)
            rootEntity = root
            applyColors(on: root)
            enableInput(on: root)
        } update: { _ in
            guard let root = rootEntity else { return }
            root.orientation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
                * simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0))
            root.scale = SIMD3<Float>(repeating: zoom)
            applyColors(on: root)
            _ = reduceMotion
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    yaw += Float(value.translation.width) * 0.003
                    pitch = min(0.45, max(-0.25, pitch + Float(value.translation.height) * 0.002))
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    zoom = min(1.8, max(0.7, Float(value)))
                }
        )
        .simultaneousGesture(
            SpatialTapGesture().targetedToAnyEntity().onEnded { value in
                let name = value.entity.name
                if let part = BodyPartRegistry.part(named: name) {
                    onSelect(part)
                }
            }
        )
        .onTapGesture(count: 2) {
            yaw = 0
            pitch = 0
            zoom = 1.1
        }
        .accessibilityLabel("3D body map")
        .accessibilityHint("Drag to rotate, pinch to zoom, double tap to reset. Tap a part to edit status.")
    }

    private static func loadBodyRoot() async -> Entity {
        let root = Entity()
        root.name = "bodyRoot"
        if let url = Bundle.main.url(forResource: "body", withExtension: "usdz", subdirectory: "Models")
            ?? Bundle.main.url(forResource: "body", withExtension: "usdz") {
            do {
                let loaded = try await Entity(contentsOf: url)
                root.addChild(loaded)
            } catch {
                root.addChild(makeProceduralBody())
            }
        } else {
            root.addChild(makeProceduralBody())
        }
        return root
    }

    private func applyColors(on root: Entity) {
        for part in BodyPart.allCases {
            guard let entity = root.findEntity(named: part.rawValue) else { continue }
            let status = statusForPart(part)
            let color = uiColor(for: status.0, intensity: status.1)
            if var model = entity.components[ModelComponent.self] {
                model.materials = [SimpleMaterial(color: color, isMetallic: false)]
                entity.components.set(model)
            }
        }
    }

    private func enableInput(on root: Entity) {
        for part in BodyPart.allCases {
            guard let entity = root.findEntity(named: part.rawValue) else { continue }
            entity.components.set(InputTargetComponent())
            entity.generateCollisionShapes(recursive: false)
        }
    }

    private func uiColor(for status: BodyStatus, intensity: Double) -> UIColor {
        switch status {
        case .healthy:
            return UIColor(red: 0.76, green: 0.60, blue: 0.48, alpha: 1)
        case .worked:
            return UIColor.yellow.withAlphaComponent(CGFloat(0.35 + 0.4 * intensity))
        case .sore:
            return UIColor.systemYellow.withAlphaComponent(0.75)
        case .injured:
            return UIColor.systemRed.withAlphaComponent(0.85)
        }
    }

    /// Neutral low-poly stand-in whose child names match `BodyPart` raw values.
    private static func makeProceduralBody() -> Entity {
        let root = Entity()
        root.name = "proceduralBody"

        func box(_ name: String, size: SIMD3<Float>, position: SIMD3<Float>) -> Entity {
            let mesh = MeshResource.generateBox(size: size, cornerRadius: 0.01)
            let material = SimpleMaterial(
                color: UIColor(red: 0.76, green: 0.60, blue: 0.48, alpha: 1),
                isMetallic: false
            )
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.name = name
            entity.position = position
            return entity
        }

        let parts: [(BodyPart, SIMD3<Float>, SIMD3<Float>)] = [
            (.head, [0.16, 0.16, 0.16], [0, 1.55, 0]),
            (.neck, [0.08, 0.08, 0.08], [0, 1.42, 0]),
            (.chest, [0.32, 0.22, 0.14], [0, 1.22, 0]),
            (.upperBack, [0.32, 0.18, 0.08], [0, 1.24, -0.08]),
            (.abs, [0.26, 0.2, 0.12], [0, 1.0, 0]),
            (.lowerBack, [0.26, 0.16, 0.08], [0, 1.0, -0.07]),
            (.leftShoulder, [0.12, 0.1, 0.1], [-0.22, 1.28, 0]),
            (.rightShoulder, [0.12, 0.1, 0.1], [0.22, 1.28, 0]),
            (.leftBicep, [0.08, 0.18, 0.08], [-0.3, 1.12, 0]),
            (.rightBicep, [0.08, 0.18, 0.08], [0.3, 1.12, 0]),
            (.leftTricep, [0.07, 0.16, 0.07], [-0.3, 1.12, -0.05]),
            (.rightTricep, [0.07, 0.16, 0.07], [0.3, 1.12, -0.05]),
            (.leftForearm, [0.07, 0.18, 0.07], [-0.32, 0.9, 0]),
            (.rightForearm, [0.07, 0.18, 0.07], [0.32, 0.9, 0]),
            (.leftHand, [0.07, 0.08, 0.04], [-0.32, 0.76, 0]),
            (.rightHand, [0.07, 0.08, 0.04], [0.32, 0.76, 0]),
            (.glutes, [0.28, 0.12, 0.12], [0, 0.84, -0.04]),
            (.leftHip, [0.12, 0.1, 0.1], [-0.1, 0.84, 0]),
            (.rightHip, [0.12, 0.1, 0.1], [0.1, 0.84, 0]),
            (.leftQuad, [0.11, 0.28, 0.11], [-0.1, 0.58, 0]),
            (.rightQuad, [0.11, 0.28, 0.11], [0.1, 0.58, 0]),
            (.leftHamstring, [0.1, 0.26, 0.1], [-0.1, 0.58, -0.05]),
            (.rightHamstring, [0.1, 0.26, 0.1], [0.1, 0.58, -0.05]),
            (.leftKnee, [0.1, 0.08, 0.1], [-0.1, 0.4, 0]),
            (.rightKnee, [0.1, 0.08, 0.1], [0.1, 0.4, 0]),
            (.leftCalf, [0.09, 0.22, 0.09], [-0.1, 0.24, 0]),
            (.rightCalf, [0.09, 0.22, 0.09], [0.1, 0.24, 0]),
            (.leftAnkle, [0.08, 0.06, 0.08], [-0.1, 0.1, 0]),
            (.rightAnkle, [0.08, 0.06, 0.08], [0.1, 0.1, 0]),
            (.leftFoot, [0.1, 0.05, 0.16], [-0.1, 0.04, 0.04]),
            (.rightFoot, [0.1, 0.05, 0.16], [0.1, 0.04, 0.04]),
        ]

        for (part, size, position) in parts {
            root.addChild(box(part.rawValue, size: size, position: position))
        }
        root.position = SIMD3<Float>(0, -0.9, -1.8)
        return root
    }
}
