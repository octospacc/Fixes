import SwiftUI
import SwiftData

@main
struct TallyApp: App {
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Consumable.self,
            ConsumptionEntry.self
        ])
        let configuration = ModelConfiguration("Tally", schema: schema)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create the Tally data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(nil)
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .defaultSize(width: 1180, height: 800)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}
