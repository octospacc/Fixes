import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        switch cleaned.count {
        case 8:
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            alpha = Double(value & 0xFF) / 255
        case 6:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            alpha = 1
        case 3:
            let r = (value >> 8) & 0xF
            let g = (value >> 4) & 0xF
            let b = value & 0xF
            red = Double(r * 17) / 255
            green = Double(g * 17) / 255
            blue = Double(b * 17) / 255
            alpha = 1
        default:
            red = 0.5
            green = 0.5
            blue = 0.5
            alpha = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension Color {
    static var tallyAccent: Color { Color("Accent") }
    static var tallyAccentSoft: Color { Color("AccentSoft") }
    static var tallyCanvas: Color { Color("Canvas") }
    static var tallySurface: Color { Color("Surface") }
    static var tallyInk: Color { Color("Ink") }
    static var tallyMuted: Color { Color("Muted") }
    static var tallyHairline: Color { Color("Hairline") }
}

extension ShapeStyle where Self == Color {
    static var tallyAccent: Color { .init("Accent") }
    static var tallyAccentSoft: Color { .init("AccentSoft") }
    static var tallyCanvas: Color { .init("Canvas") }
    static var tallySurface: Color { .init("Surface") }
    static var tallyInk: Color { .init("Ink") }
    static var tallyMuted: Color { .init("Muted") }
    static var tallyHairline: Color { .init("Hairline") }
}
