import Foundation

protocol FoodRepositoryProtocol {
    func loadFoodItems() -> [FoodItem]
}

struct FoodRepository: FoodRepositoryProtocol {
    func loadFoodItems() -> [FoodItem] {
        return [
            FoodItem(
                name: "Nasi Goreng",
                restaurant: "Warung Nusantara",
                cuisine: .local,
                distanceKm: 0.8,
                rating: 4.5,
                tags: [.glutenFree],
                allergens: [],
                religiousCompliance: [.halal],
                nutrients: [.sodium],
                description: "Classic Indonesian fried rice with veggies and egg.",
                imageName: nil
            ),
            FoodItem(
                name: "Gado-Gado",
                restaurant: "Jakarta Vegan Corner",
                cuisine: .local,
                distanceKm: 1.2,
                rating: 4.6,
                tags: [.vegan, .glutenFree],
                allergens: [.peanuts],
                religiousCompliance: [.halal],
                nutrients: [.sugar],
                description: "Indonesian salad with peanut sauce.",
                imageName: nil
            ),
            FoodItem(
                name: "Grilled Salmon Bowl",
                restaurant: "Sea Breeze",
                cuisine: .western,
                distanceKm: 3.2,
                rating: 4.7,
                tags: [.pescatarian, .glutenFree],
                allergens: [.fish],
                religiousCompliance: [.halal],
                nutrients: [],
                description: "Salmon, greens, and quinoa bowl.",
                imageName: nil
            ),
            FoodItem(
                name: "Sushi Set",
                restaurant: "Tokyo Bites",
                cuisine: .asian,
                distanceKm: 2.0,
                rating: 4.3,
                tags: [.pescatarian],
                allergens: [.fish],
                religiousCompliance: [.halal],
                nutrients: [.sodium],
                description: "Assorted sushi with miso soup.",
                imageName: nil,
                uncertainIngredients: true
            ),
            FoodItem(
                name: "Falafel Wrap",
                restaurant: "Mediterraneo",
                cuisine: .western,
                distanceKm: 1.8,
                rating: 4.2,
                tags: [.vegan],
                allergens: [],
                religiousCompliance: [.halal, .kosher],
                nutrients: [],
                description: "Crispy falafel with tahini in wrap.",
                imageName: nil
            ),
            FoodItem(
                name: "Chicken Satay",
                restaurant: "Satay Street",
                cuisine: .local,
                distanceKm: 0.5,
                rating: 4.4,
                tags: [],
                allergens: [],
                religiousCompliance: [.halal],
                nutrients: [.saturatedFat],
                description: "Grilled chicken skewers with peanut sauce.",
                imageName: nil
            )
        ]
    }
}