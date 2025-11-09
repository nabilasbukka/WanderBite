import Foundation

struct FoodItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let restaurant: String
    let cuisine: Cuisine
    let distanceKm: Double
    let rating: Double
    let tags: Set<DietaryTag>
    let allergens: Set<Allergen>
    let religiousCompliance: Set<ReligiousRule>
    let nutrients: Set<Nutrient>
    let description: String
    let imageName: String? // placeholder for asset name or system image
    let uncertainIngredients: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        restaurant: String,
        cuisine: Cuisine,
        distanceKm: Double,
        rating: Double,
        tags: Set<DietaryTag> = [],
        allergens: Set<Allergen> = [],
        religiousCompliance: Set<ReligiousRule> = [],
        nutrients: Set<Nutrient> = [],
        description: String = "",
        imageName: String? = nil,
        uncertainIngredients: Bool = false
    ) {
        self.id = id
        self.name = name
        self.restaurant = restaurant
        self.cuisine = cuisine
        self.distanceKm = distanceKm
        self.rating = rating
        self.tags = tags
        self.allergens = allergens
        self.religiousCompliance = religiousCompliance
        self.nutrients = nutrients
        self.description = description
        self.imageName = imageName
        self.uncertainIngredients = uncertainIngredients
    }
}