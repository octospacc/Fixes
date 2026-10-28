import Foundation
import SwiftUI

/// Broad buckets used for item suggestions, colors, and statistical breakdowns.
enum ConsumableCategory: String, CaseIterable, Codable, Identifiable {
    case smoking
    case drinks
    case food
    case snacks
    case gambling
    case gaming
    case wellness
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smoking: "Smoking"
        case .drinks: "Drinks"
        case .food: "Food"
        case .snacks: "Snacks"
        case .gambling: "Gambling"
        case .gaming: "Gaming"
        case .wellness: "Wellness"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .smoking: "smoke.fill"
        case .drinks: "cup.and.saucer.fill"
        case .food: "fork.knife"
        case .snacks: "takeoutbag.and.cup.and.straw.fill"
        case .gambling: "ticket.fill"
        case .gaming: "gamecontroller.fill"
        case .wellness: "leaf.fill"
        case .other: "circle.grid.2x2.fill"
        }
    }

    var tintHex: String {
        switch self {
        case .smoking: "B65B43"
        case .drinks: "A77443"
        case .food: "667B5D"
        case .snacks: "C7973A"
        case .gambling: "826AA6"
        case .gaming: "5A739A"
        case .wellness: "5D8A86"
        case .other: "7A7C74"
        }
    }

    var color: Color { Color(hex: tintHex) }
}
