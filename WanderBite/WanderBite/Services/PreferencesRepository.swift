import Foundation

protocol PreferencesRepositoryProtocol {
    func loadPreferences() -> UserPreferences
}

struct PreferencesRepository: PreferencesRepositoryProtocol {
    func loadPreferences() -> UserPreferences {
        // Dummy in-memory preferences from onboarding
        UserPreferences(
            name: "Traveler",
            city: "Jakarta",
            allergies: [.peanuts],
            dietaryPreferences: [.glutenFree, .pescatarian],
            religiousRules: [.halal],
            nutrientsToAvoid: [.sugar]
        )
    }
}