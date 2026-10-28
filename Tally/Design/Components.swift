import SwiftUI

struct TallyMark: View {
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(TallyTheme.accentGradient)
            HStack(spacing: size * 0.075) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.94))
                        .frame(width: size * 0.06, height: size * 0.36)
                }
            }
            .offset(y: size * 0.01)
            Capsule()
                .fill(Color.white)
                .frame(width: size * 0.06, height: size * 0.47)
                .rotationEffect(.degrees(58))
                .offset(x: size * 0.02, y: -size * 0.01)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct BrandLockup: View {
    var compact = false

    var body: some View {
        HStack(spacing: 11) {
            TallyMark(size: compact ? 30 : 36)
            VStack(alignment: .leading, spacing: 1) {
                Text("Tally")
                    .font(.system(size: compact ? 19 : 22, weight: .semibold, design: .serif))
                    .foregroundStyle(TallyTheme.ink)
                if !compact {
                    Text("everyday ledger")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(TallyTheme.muted)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tally, everyday ledger")
    }
}

struct ItemIcon: View {
    let symbolName: String
    let tint: Color
    var size: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
            .fill(tint.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .strokeBorder(tint.opacity(0.14), lineWidth: 1)
            )
            .overlay {
                Image(systemName: symbolName)
                    .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(TallyTheme.sectionFont)
                    .foregroundStyle(TallyTheme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(TallyTheme.captionFont)
                        .foregroundStyle(TallyTheme.muted)
                }
            }
            Spacer(minLength: 12)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(TallyTheme.accent)
                    .buttonStyle(.plain)
            }
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var detail: String?
    var symbolName: String
    var tint: Color = TallyTheme.accent
    var filled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: symbolName)
                    .font(.system(size: 11, weight: .bold))
                Text(title.uppercased())
                    .font(TallyTheme.overlineFont)
                    .tracking(0.7)
            }
            .foregroundStyle(filled ? Color.white.opacity(0.92) : tint)

            Text(value)
                .font(TallyTheme.numberFont)
                .monospacedDigit()
                .foregroundStyle(filled ? Color.white : TallyTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let detail {
                Text(detail)
                    .font(TallyTheme.captionFont)
                    .foregroundStyle(filled ? Color.white.opacity(0.80) : TallyTheme.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(filled ? AnyShapeStyle(TallyTheme.accentGradient) : AnyShapeStyle(TallyTheme.surface))
        }
        .overlay {
            if !filled {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(TallyTheme.hairline.opacity(0.85), lineWidth: 1)
            }
        }
        .shadow(color: filled ? TallyTheme.accent.opacity(0.16) : Color.black.opacity(0.025), radius: 14, x: 0, y: 7)
        .accessibilityElement(children: .combine)
    }
}

struct TallyEmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TallyTheme.accentSoft)
                    .frame(width: 62, height: 62)
                Image(systemName: symbol)
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(TallyTheme.accent)
            }
            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(TallyTheme.ink)
                Text(message)
                    .font(TallyTheme.bodyFont)
                    .foregroundStyle(TallyTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SoftButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 22)
        .accessibilityElement(children: .contain)
    }
}

struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: TallyTheme.controlRadius, style: .continuous)
                    .fill(TallyTheme.accentGradient)
            )
            .shadow(color: TallyTheme.accent.opacity(0.24), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(TallyTheme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(TallyTheme.surface)
            )
            .overlay(Capsule().strokeBorder(TallyTheme.hairline, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ToastBanner: View {
    let symbol: String
    let message: String
    var undo: (() -> Void)?

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(TallyTheme.accent)
                .frame(width: 26, height: 26)
                .background(Circle().fill(TallyTheme.accentSoft))

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(TallyTheme.ink)
                .lineLimit(2)

            if let undo {
                Spacer(minLength: 6)
                Button("Undo", action: undo)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(TallyTheme.accent)
                    .buttonStyle(.plain)
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(TallyTheme.hairline.opacity(0.7), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
    }
}

struct PriceText: View {
    let cents: Int?
    let currencyCode: String
    var emphasized = false

    var body: some View {
        Text(Money.display(cents, currencyCode: currencyCode))
            .font(.system(size: emphasized ? 15 : 13, weight: emphasized ? .semibold : .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(cents == nil ? TallyTheme.muted : TallyTheme.ink)
    }
}

struct ChipLabel: View {
    let title: String
    var symbolName: String?
    var selected: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            if let symbolName {
                Image(systemName: symbolName)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(selected ? Color.white : TallyTheme.muted)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(selected ? AnyShapeStyle(TallyTheme.accentGradient) : AnyShapeStyle(TallyTheme.surface)))
        .overlay(Capsule().strokeBorder(selected ? Color.clear : TallyTheme.hairline, lineWidth: 1))
    }
}
