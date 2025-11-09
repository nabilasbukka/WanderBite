import Foundation

protocol PreferencesRepositoryProtocol {
    func loadPreferences() -> UserPreferences
}

struct PreferencesRepository: PreferencesRepositoryProtocol {
    func loadPreferences() -> UserPreferences {
        // Dummy in-memory preferences from onboarding
        UserPreferences(
            name: "Afina",
            city: "Jakarta",
            allergies: [.eggs],
            dietaryPreferences: [.glutenFree],
            religiousRules: [.halal],
            nutrientsToAvoid: [.sugar]
        )
    }
}
