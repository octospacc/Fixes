import SwiftUI
import CloudKit

struct SettingsView: View {
    @Environment(\.cloudSyncEnabled) private var cloudSyncEnabled
    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

    @State private var accountStatus: CKAccountStatus?
    @State private var accountCheckFailed = false

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
            return "Uses the iCloud account signed in on your devices. No Tally account is needed."
        }
        switch accountStatus {
        case .available:
            return "Uses the iCloud account signed in on your devices. No Tally account is needed."
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

            Section("About") {
                LabeledContent("Version", value: appVersion)
            }
        }
        .navigationTitle("Settings")
        .task {
            await checkAccountStatus()
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
