import SwiftUI
import SwiftData
import CloudKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.cloudSyncEnabled) private var cloudSyncEnabled
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()
    
    @Query(sort: [SortDescriptor(\ConsumptionEntry.timestamp, order: .reverse)]) private var entries: [ConsumptionEntry]
    @Query private var items: [Consumable]

    @State private var accountStatus: CKAccountStatus?
    @State private var accountCheckFailed = false
    
    @State private var showingImporter = false
    @State private var importAlertMessage: String?
    @State private var showImportAlert = false
    
    @State private var showResetConfirmation = false

    private var currencyCodes: [String] {
        var codes = Set(Locale.commonISOCurrencyCodes)
        codes.insert(currencyCode)
        if let localCurrency = Locale.current.currency?.identifier {
            codes.insert(localCurrency)
        }
        return codes.sorted()
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var syncValue: String {
        guard cloudSyncEnabled else { return "Unavailable" }
        guard let accountStatus else {
            return accountCheckFailed ? "Unavailable" : "Checking…"
        }
        switch accountStatus {
        case .available: return "On"
        case .noAccount: return "No Account"
        case .restricted: return "Restricted"
        case .couldNotDetermine: return "Unavailable"
        case .temporarilyUnavailable: return "Unavailable"
        @unknown default: return "Unavailable"
        }
    }

    private var syncDetail: String {
        guard cloudSyncEnabled else {
            return "Data is stored on this device."
        }
        guard let accountStatus else {
            return "Uses the iCloud account signed in on your devices. No Fixes account is needed."
        }
        switch accountStatus {
        case .available:
            return "Uses the iCloud account signed in on your devices. No Fixes account is needed."
        case .noAccount:
            return "Sign in to iCloud on this device to sync."
        case .restricted, .couldNotDetermine, .temporarilyUnavailable:
            return "Data is stored on this device."
        @unknown default:
            return "Data is stored on this device."
        }
    }

    var body: some View {
        Form {
            Section("Currency") {
                Picker("Currency", selection: $currencyCode) {
                    ForEach(currencyCodes, id: \.self) { code in
                        Text("\(code) · \(Money.symbol(for: code))")
                            .tag(code)
                    }
                }
            }

            Section("iCloud") {
                LabeledContent("Sync") {
                    if cloudSyncEnabled, accountStatus == nil, !accountCheckFailed {
                        ProgressView()
                    } else {
                        Text(syncValue)
                    }
                }
                Text(syncDetail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Section("Data Management") {
                if let exportURL = CSVManager.generateCSV(entries: entries) {
                    ShareLink(item: exportURL) {
                        Label("Export to CSV", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Label("Export to CSV", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    showingImporter = true
                } label: {
                    Label("Import from CSV", systemImage: "square.and.arrow.down")
                }
            }
            
            Section("Danger Zone") {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Erase All Data", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
            }
        }
        #if os(macOS)
        .formStyle(.grouped) // <--- Fixes the layout on macOS
        #endif
        .navigationTitle("Settings")
        .task {
            await checkAccountStatus()
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText]
        ) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    do {
                        try CSVManager.importCSV(url: url, modelContext: modelContext, existingItems: items, existingEntries: entries)
                        importAlertMessage = "Data successfully imported without duplicates!"
                    } catch {
                        importAlertMessage = "Failed to import CSV: \(error.localizedDescription)"
                    }
                } else {
                    importAlertMessage = "Could not access the file securely."
                }
                showImportAlert = true
            case .failure(let error):
                importAlertMessage = "Failed to select file: \(error.localizedDescription)"
                showImportAlert = true
            }
        }
        .alert("Import Status", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let importAlertMessage {
                Text(importAlertMessage)
            }
        }
        .alert("Erase All Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Erase Data", role: .destructive) {
                resetDatabase()
            }
        } message: {
            Text("This will permanently delete all items and entries from your database. If iCloud sync is enabled, this will also delete the data across all your devices. This action cannot be undone.")
        }
    }

    private func resetDatabase() {
        do {
            try modelContext.delete(model: ConsumptionEntry.self)
            try modelContext.delete(model: Consumable.self)
            try modelContext.save()
        } catch {
            print("Failed to clear database: \(error.localizedDescription)")
        }
    }

    private func checkAccountStatus() async {
        guard cloudSyncEnabled else { return }
        do {
            let container = CKContainer(identifier: CloudSync.containerIdentifier)
            accountStatus = try await container.accountStatus()
        } catch {
            accountCheckFailed = true
        }
    }
}
