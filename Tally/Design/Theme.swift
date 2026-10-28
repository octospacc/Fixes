import SwiftUI

enum TallyTheme {
    static let accent = Color.tallyAccent
    static let accentSoft = Color.tallyAccentSoft
    static let canvas = Color.tallyCanvas
    static let surface = Color.tallySurface
    static let ink = Color.tallyInk
    static let muted = Color.tallyMuted
    static let hairline = Color.tallyHairline

    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 14
    static let pagePadding: CGFloat = 20
    static let pageMaxWidth: CGFloat = 980

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "C15532"), Color(hex: "9F391F")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let displayFont = Font.system(size: 38, weight: .semibold, design: .serif)
    static let titleFont = Font.system(size: 22, weight: .semibold, design: .serif)
    static let sectionFont = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let overlineFont = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let numberFont = Font.system(size: 26, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .medium, design: .rounded)
}

struct TallyBackground: View {
    var body: some View {
        ZStack {
            TallyTheme.canvas
            GeometryReader { proxy in
                Circle()
                    .fill(TallyTheme.accent.opacity(0.075))
                    .frame(width: proxy.size.width * 0.8, height: proxy.size.width * 0.8)
                    .blur(radius: 90)
                    .offset(x: proxy.size.width * 0.45, y: -proxy.size.height * 0.25)
                Circle()
                    .fill(Color(hex: "C7973A").opacity(0.045))
                    .frame(width: proxy.size.width * 0.55)
                    .blur(radius: 80)
                    .offset(x: -proxy.size.width * 0.35, y: proxy.size.height * 0.55)
            }
            .clipped()
        }
        .ignoresSafeArea()
    }
}

extension View {
    func tallyCard(padding: CGFloat = 18, radius: CGFloat = TallyTheme.cardRadius) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(TallyTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(TallyTheme.hairline.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.035), radius: 16, x: 0, y: 8)
    }

    func tallyPageWidth() -> some View {
        frame(maxWidth: TallyTheme.pageMaxWidth)
            .frame(maxWidth: .infinity)
    }
}
