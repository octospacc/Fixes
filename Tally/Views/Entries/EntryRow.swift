import SwiftUI

struct EntryRow: View {
    let entry: ConsumptionEntry
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.category.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.itemName)
                    if entry.quantity > 1 {
                        Text("×\(entry.quantity)")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 4) {
                    Text(entry.hasTime ? TallyDateFormat.time(entry.timestamp) : "All day")
                    if !entry.note.trimmed.isEmpty {
                        Text("·")
                        Text(entry.note)
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if let spend = entry.totalSpendCents {
                Text(Money.display(spend, currencyCode: currencyCode))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Forces the bounding box to expand
        .contentShape(Rectangle()) // Makes the empty whitespace fully tappable
        .accessibilityElement(children: .combine)
    }
}
