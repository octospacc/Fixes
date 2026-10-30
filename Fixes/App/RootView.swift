import SwiftUI
import SwiftData

enum AppSection: String, CaseIterable, Identifiable {
    case today
    case history
    case statistics
    case items
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .history: "History"
        case .statistics: "Statistics"
        case .items: "Items"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "calendar"
        case .history: "clock"
        case .statistics: "chart.bar"
        case .items: "list.bullet"
        case .settings: "gearshape"
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: AppSection = .today

    var body: some View {
        Group {
            #if os(macOS)
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(AppSection.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .tag(section)
                }
            }
            .navigationTitle("Fixes")
        } detail: {
            NavigationStack {
                destination(for: selection)
            }
        }
        #else
        TabView(selection: $selection) {
            NavigationStack {
                TodayView(onAddItems: { selection = .items })
            }
            .tabItem { Label("Today", systemImage: AppSection.today.systemImage) }
            .tag(AppSection.today)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: AppSection.history.systemImage) }
            .tag(AppSection.history)

            NavigationStack {
                StatsView()
            }
            .tabItem { Label("Statistics", systemImage: AppSection.statistics.systemImage) }
            .tag(AppSection.statistics)

            NavigationStack {
                ItemsView()
            }
            .tabItem { Label("Items", systemImage: AppSection.items.systemImage) }
            .tag(AppSection.items)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: AppSection.settings.systemImage) }
            .tag(AppSection.settings)
            }
            #endif
        }
        .task {
            #if DEBUG
            DemoDataSeeder.seedIfRequested(in: modelContext)
            applyDebugLaunchArguments()
            #endif
        }
    }

    @ViewBuilder
    private func destination(for section: AppSection) -> some View {
        switch section {
        case .today: TodayView(onAddItems: { selection = .items })
        case .history: HistoryView()
        case .statistics: StatsView()
        case .items: ItemsView()
        case .settings: SettingsView()
        }
    }

    #if DEBUG
    private func applyDebugLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-startTab"),
              arguments.indices.contains(index + 1),
              let section = AppSection(rawValue: arguments[index + 1]) else { return }
        selection = section
    }
    #endif
}
