import Foundation

enum ConsumableCategory: String, CaseIterable, Codable, Identifiable {
    case drinks
    case food
    case snacks
    case smoking
    case gambling
    case gaming
    case wellness
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .drinks: "Drinks"
        case .food: "Food"
        case .snacks: "Snacks"
        case .smoking: "Smoking"
        case .gambling: "Gambling"
        case .gaming: "Gaming"
        case .wellness: "Wellness"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .drinks: "cup.and.saucer"
        case .food: "fork.knife"
        case .snacks: "takeoutbag.and.cup.and.straw"
        case .smoking: "smoke"
        case .gambling: "ticket"
        case .gaming: "gamecontroller"
        case .wellness: "heart"
        case .other: "square.grid.2x2"
        }
    }
}
