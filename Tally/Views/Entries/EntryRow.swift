import SwiftUI

struct EntryRow: View {
    let entry: ConsumptionEntry
    let currencyCode: String
    var showsMenu = true
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onLogAgain: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            ItemIcon(symbolName: entry.itemSymbolName, tint: entry.itemColor, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(entry.itemName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(TallyTheme.ink)
                        .lineLimit(1)
                    if entry.quantity > 1 {
                        Text("×\(entry.quantity)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.itemColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(entry.itemColor.opacity(0.12)))
                    }
                }

                HStack(spacing: 5) {
                    Text(entry.hasTime ? TallyDateFormat.time(entry.timestamp) : "All day")
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                    if !entry.note.trimmed.isEmpty {
                        Text("·")
                            .foregroundStyle(TallyTheme.muted.opacity(0.6))
                        Text(entry.note)
                            .font(TallyTheme.captionFont)
                            .foregroundStyle(TallyTheme.muted)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 4)

            if let spend = entry.totalSpendCents {
                PriceText(cents: spend, currencyCode: currencyCode, emphasized: true)
            }

            if showsMenu, onEdit != nil || onDelete != nil || onLogAgain != nil {
                Menu {
                    if let onEdit {
                        Button { onEdit() } label: { Label("Edit entry", systemImage: "pencil") }
                    }
                    if let onLogAgain {
                        Button { onLogAgain() } label: { Label("Log again now", systemImage: "plus.circle") }
                    }
                    if onDelete != nil || onLogAgain != nil || onEdit != nil {
                        Divider()
                    }
                    if let onDelete {
                        Button(role: .destructive) { onDelete() } label: {
                            Label("Delete entry", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TallyTheme.muted)
                        .frame(width: 30, height: 36)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .accessibilityLabel("Entry actions for \(entry.itemName)")
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
    }
}

struct QuickAddTile: View {
    let item: Consumable
    let currencyCode: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ItemIcon(symbolName: item.symbolName, tint: item.color, size: 38)
                    Spacer(minLength: 0)
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(item.color)
                        .frame(width: 25, height: 25)
                        .background(Circle().fill(item.color.opacity(0.13)))
                }

                Text(item.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(TallyTheme.ink)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let price = item.unitPriceCents {
                        Text(Money.display(price, currencyCode: currencyCode))
                            .font(TallyTheme.captionFont)
                            .foregroundStyle(TallyTheme.muted)
                    } else {
                        Text("No price")
                            .font(TallyTheme.captionFont)
                            .foregroundStyle(TallyTheme.muted.opacity(0.8))
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [TallyTheme.surface, item.color.opacity(0.045)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(TallyTheme.hairline.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.025), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(QuickAddTileButtonStyle())
        .accessibilityLabel("Log one \(item.name) now")
    }
}

struct QuickAddTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
