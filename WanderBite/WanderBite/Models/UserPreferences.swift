import Foundation

struct UserPreferences: Codable {
    var name: String
    var city: String
    var allergies: Set<Allergen>
    var dietaryPreferences: Set<DietaryTag>
    var religiousRules: Set<ReligiousRule>
    var nutrientsToAvoid: Set<Nutrient>
    
    static let sample = UserPreferences(
        name: "Afina",
        city: "Singapore",
        allergies: [.eggs],
        dietaryPreferences: [.glutenFree],
        religiousRules: [.halal],
        nutrientsToAvoid: [.sugar]
    )
}

extension UserPreferences {
    func withCity(_ newCity: String) -> UserPreferences {
        UserPreferences(
            name: self.name,
            city: newCity,
            allergies: self.allergies,
            dietaryPreferences: self.dietaryPreferences,
            religiousRules: self.religiousRules,
            nutrientsToAvoid: self.nutrientsToAvoid
        )
    }
    
    func withDietaryPreferences(_ tags: Set<DietaryTag>) -> UserPreferences {
        UserPreferences(
            name: self.name,
            city: self.city,
            allergies: self.allergies,
            dietaryPreferences: tags,
            religiousRules: self.religiousRules,
            nutrientsToAvoid: self.nutrientsToAvoid
        )
    }
}
