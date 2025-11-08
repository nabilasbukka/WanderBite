import Foundation
import SwiftUI

enum DietaryTag: String, CaseIterable, Codable, Identifiable {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case keto = "Keto"
    case glutenFree = "Gluten-Free"
    case pescatarian = "Pescatarian"
    var id: String { rawValue }
}

enum Allergen: String, CaseIterable, Codable, Identifiable {
    case milk = "Milk"
    case eggs = "Eggs"
    case peanuts = "Peanuts"
    case treeNuts = "Tree Nuts"
    case shellfish = "Shellfish"
    case fish = "Fish"
    case soy = "Soy"
    case wheat = "Wheat"
    var id: String { rawValue }
}

enum ReligiousRule: String, CaseIterable, Codable, Identifiable {
    case halal = "Halal"
    case kosher = "Kosher"
    var id: String { rawValue }
}

enum Nutrient: String, CaseIterable, Codable, Identifiable {
    case sugar = "Sugar"
    case sodium = "Sodium"
    case saturatedFat = "Saturated Fat"
    var id: String { rawValue }
}

enum Cuisine: String, CaseIterable, Codable, Identifiable {
    case all = "All"
    case local = "Local"
    case asian = "Asian"
    case western = "Western"
    var id: String { rawValue }
}

enum SafetyStatus: String, Codable, Identifiable {
    case strictSafe = "STRICT-SAFE"
    case safe = "SAFE"
    case checkDetails = "CHECK DETAILS"
    var id: String { rawValue }
    var iconName: String {
        switch self {
        case .strictSafe: return "checkmark.shield"
        case .safe: return "checkmark.circle"
        case .checkDetails: return "exclamationmark.triangle"
        }
    }
    var color: Color {
        switch self {
        case .strictSafe: return .green
        case .safe: return .teal
        case .checkDetails: return .orange
        }
    }
}