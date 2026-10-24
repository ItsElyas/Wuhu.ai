import Foundation
import SwiftData

/// Owns the app's SwiftData containers.
/// - `live`: the user's real, on-disk store (unchanged location).
/// - `demo`: a separate in-memory store seeded with sample data. Real data is never touched,
///   and turning demo mode off simply switches back to `live`.
@MainActor
final class ModelContainerStore {
    static let shared = ModelContainerStore()

    static let schema = Schema([
        WorkoutRecord.self,
        ChatMessage.self,
        BodyPartStatusRecord.self,
        CachedScoreResult.self,
        HubExercise.self,
        HubSetLog.self,
        HubSession.self,
        HubRunSegment.self,
    ])

    private(set) lazy var live: ModelContainer = Self.makeLive()
    private var demoContainer: ModelContainer?

    /// Created and seeded on first use; recreated after `resetDemo()`.
    var demo: ModelContainer {
        if let demoContainer { return demoContainer }
        let container = Self.makeInMemory()
        DemoDataSeeder.seed(into: container.mainContext)
        demoContainer = container
        return container
    }

    func container(demoMode: Bool) -> ModelContainer {
        demoMode ? demo : live
    }

    /// Next demo session starts from fresh sample data.
    func resetDemo() {
        demoContainer = nil
    }

    private static func makeLive() -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: false)])
        } catch {
            return makeInMemory()
        }
    }

    private static func makeInMemory() -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        } catch {
            preconditionFailure("Could not create ModelContainer: \(error)")
        }
    }
}
