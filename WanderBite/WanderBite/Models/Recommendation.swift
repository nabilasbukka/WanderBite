import Foundation

struct Recommendation: Identifiable, Codable {
    var id = UUID()
    let item: FoodItem
    let score: Double
    let reason: String
    let isNearMatch: Bool
}
