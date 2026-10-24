import SwiftUI
import SwiftData

@main
struct WuhuApp: App {
    @State private var environment = AppEnvironment()
    private let containers = ModelContainerStore.shared

    var body: some Scene {
        WindowGroup {
            // Re-creating RootView on toggle re-runs bootstrap against the new store.
            RootView()
                .id(environment.settings.demoMode)
                .environment(environment)
                .modelContainer(containers.container(demoMode: environment.settings.demoMode))
        }
    }
}
