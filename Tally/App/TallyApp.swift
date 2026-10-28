import SwiftUI
import SwiftData

@main
struct TallyApp: App {
    private let modelContainer: ModelContainer
    private let cloudSyncEnabled: Bool

    init() {
        let schema = Schema([
            Consumable.self,
            ConsumptionEntry.self
        ])

        let cloudConfiguration = ModelConfiguration(
            "Tally",
            schema: schema,
            cloudKitDatabase: .private(CloudSync.containerIdentifier)
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [cloudConfiguration]
            )
            cloudSyncEnabled = true
        } catch {
            // An unsigned or locally signed build has no CloudKit entitlement.
            // Keep the app usable locally; signed builds use iCloud.
            print("CloudKit store unavailable, using local storage: \(error)")
            let localConfiguration = ModelConfiguration(
                "Tally",
                schema: schema,
                cloudKitDatabase: .none
            )
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [localConfiguration]
                )
                cloudSyncEnabled = false
            } catch {
                fatalError("Unable to create the Tally data store: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.cloudSyncEnabled, cloudSyncEnabled)
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .defaultSize(width: 960, height: 680)
        #endif
    }
}

private struct CloudSyncEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var cloudSyncEnabled: Bool {
        get { self[CloudSyncEnabledKey.self] }
        set { self[CloudSyncEnabledKey.self] = newValue }
    }
}
