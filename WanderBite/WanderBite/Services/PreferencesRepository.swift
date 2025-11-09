import Foundation
import SwiftData

@MainActor
protocol PreferencesRepositoryProtocol {
    func loadPreferences() -> UserPreferences
}


@MainActor
final class PreferencesRepository: PreferencesRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadPreferences() -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        } else {
            let fresh = UserPreferences(
                name: "",
                city: "",
                allergies: [],
                dietaryPreferences: [],
                religiousRules: [],
                isOnboarded: false
            )
            context.insert(fresh)
            try? context.save()
            return fresh
        }
    }
}
