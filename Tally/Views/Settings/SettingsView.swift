import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter
    @AppStorage("currencyCode") private var currencyCode = Money.currencyCode()

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
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                preferences
                privacy
                about
            }
            .padding(.horizontal, TallyTheme.pagePadding)
            .padding(.top, 6)
            .padding(.bottom, 44)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(TallyBackground())
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TallyTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("TALLY")
                .font(TallyTheme.overlineFont)
                .tracking(1.2)
                .foregroundStyle(TallyTheme.muted)
            Text("Make it yours.")
                .font(TallyTheme.displayFont)
                .foregroundStyle(TallyTheme.ink)
            Text("A few preferences, kept intentionally simple.")
                .font(TallyTheme.bodyFont)
                .foregroundStyle(TallyTheme.muted)
        }
    }

    private var preferences: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                settingsIcon("banknote")
                VStack(alignment: .leading, spacing: 3) {
                    Text("Currency")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(TallyTheme.ink)
                    Text("Used for item prices and spending totals")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                }
                Spacer(minLength: 12)
                Picker("Currency", selection: $currencyCode) {
                    ForEach(currencyCodes, id: \.self) { code in
                        Text("\(code) · \(Money.symbol(for: code))")
                            .tag(code)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(TallyTheme.accent)
            }
            .padding(16)

            Divider().overlay(TallyTheme.hairline).padding(.leading, 65)

            HStack(spacing: 13) {
                settingsIcon("square.grid.2x2")
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your items")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(TallyTheme.ink)
                    Text("Add, edit, archive, and set default prices")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TallyTheme.muted.opacity(0.7))
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture { router.section = .items }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)

            Divider().overlay(TallyTheme.hairline).padding(.leading, 65)

            HStack(spacing: 13) {
                settingsIcon("tag")
                VStack(alignment: .leading, spacing: 3) {
                    Text("Example total")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(TallyTheme.ink)
                    Text("How prices appear throughout Tally")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                }
                Spacer()
                Text(Money.display(1234, currencyCode: currencyCode))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(TallyTheme.ink)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: TallyTheme.cardRadius, style: .continuous)
                .fill(TallyTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TallyTheme.cardRadius, style: .continuous)
                .strokeBorder(TallyTheme.hairline.opacity(0.85), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 12, x: 0, y: 6)
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(TallyTheme.accent)
                Text("Private by default")
                    .font(TallyTheme.sectionFont)
                    .foregroundStyle(TallyTheme.ink)
            }
            Text("Tally has no account, no cloud, and no analytics. Your entries and prices live only on this device, in a local SwiftData store. Delete the app and its data goes with it.")
                .font(TallyTheme.bodyFont)
                .foregroundStyle(TallyTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 18)
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                TallyMark(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tally")
                        .font(.system(size: 21, weight: .semibold, design: .serif))
                        .foregroundStyle(TallyTheme.ink)
                    Text("everyday ledger")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(TallyTheme.muted)
                }
            }

            Text("A small, honest place to count the things you consume — and see the patterns without judgement.")
                .font(TallyTheme.bodyFont)
                .foregroundStyle(TallyTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            Divider().overlay(TallyTheme.hairline)

            HStack {
                Text("Made for iPhone, iPad, and Mac")
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(TallyTheme.muted)
                Spacer()
                Text(appVersion)
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(TallyTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tallyCard(padding: 18)
    }

    private func settingsIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(TallyTheme.accent)
            .frame(width: 34, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(TallyTheme.accentSoft)
            )
    }
}
