import SwiftUI
import SwiftData

@main
struct WuhuApp: App {
    @State private var environment = AppEnvironment()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutRecord.self,
            ChatMessage.self,
            BodyPartStatusRecord.self,
            CachedScoreResult.self,
        ])
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: false)])
        } catch {
            do {
                return try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            } catch {
                preconditionFailure("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .modelContainer(sharedModelContainer)
        }
    }
}
