import SwiftUI
import SwiftData

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case today
    case history
    case stats
    case items
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .history: "History"
        case .stats: "Statistics"
        case .items: "Items"
        case .settings: "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .today: "sun.max.fill"
        case .history: "clock.arrow.circlepath"
        case .stats: "chart.bar.xaxis"
        case .items: "square.grid.2x2.fill"
        case .settings: "gearshape.fill"
        }
    }
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var section: AppSection = .today
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var router = AppRouter()

    var body: some View {
        Group {
            #if os(macOS)
            macOSRoot
            #else
            iOSRoot
            #endif
        }
        .tint(TallyTheme.accent)
        .task {
            PresetSeeder.seedIfNeeded(in: modelContext)
            #if DEBUG
            DemoDataSeeder.seedIfRequested(in: modelContext)
            applyDebugLaunchArguments()
            #endif
        }
    }

    #if os(macOS)
    private var macOSRoot: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack {
                    BrandLockup()
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)

                List(selection: $router.section) {
                    Section("Ledger") {
                        ForEach([AppSection.today, .history, .stats]) { section in
                            Label(section.title, systemImage: section.symbolName)
                                .tag(section)
                        }
                    }
                    Section("Your library") {
                        Label(AppSection.items.title, systemImage: AppSection.items.symbolName)
                            .tag(AppSection.items)
                    }
                    Section {
                        Label(AppSection.settings.title, systemImage: AppSection.settings.symbolName)
                            .tag(AppSection.settings)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)

                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .semibold))
                    Text("Your data stays on this Mac")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .foregroundStyle(TallyTheme.muted)
                .padding(.vertical, 12)
            }
            .background(TallyTheme.canvas)
            .navigationSplitViewColumnWidth(min: 196, ideal: 218, max: 260)
        } detail: {
            NavigationStack {
                destination(for: router.section)
            }
            .background(TallyTheme.canvas)
        }
        .navigationSplitViewStyle(.balanced)
        .environmentObject(router)
    }
    #endif

    #if !os(macOS)
    private var iOSRoot: some View {
        TabView(selection: $router.section) {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label(AppSection.today.title, systemImage: AppSection.today.symbolName) }
            .tag(AppSection.today)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label(AppSection.history.title, systemImage: AppSection.history.symbolName) }
            .tag(AppSection.history)

            NavigationStack {
                StatsView()
            }
            .tabItem { Label(AppSection.stats.title, systemImage: AppSection.stats.symbolName) }
            .tag(AppSection.stats)

            NavigationStack {
                ItemsView()
            }
            .tabItem { Label(AppSection.items.title, systemImage: AppSection.items.symbolName) }
            .tag(AppSection.items)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(AppSection.settings.title, systemImage: AppSection.settings.symbolName) }
            .tag(AppSection.settings)
        }
        .environmentObject(router)
    }
    #endif

    #if DEBUG
    private func applyDebugLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-startTab"),
              arguments.indices.contains(index + 1),
              let section = AppSection(rawValue: arguments[index + 1]) else { return }
        router.section = section
    }
    #endif

    @ViewBuilder
    private func destination(for section: AppSection) -> some View {
        switch section {
        case .today: TodayView()
        case .history: HistoryView()
        case .stats: StatsView()
        case .items: ItemsView()
        case .settings: SettingsView()
        }
    }
}
