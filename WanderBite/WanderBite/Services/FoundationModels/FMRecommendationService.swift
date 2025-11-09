import Foundation

protocol RecommendationServiceProtocol {
    func recommend(
        preferences: UserPreferences,
        items: [FoodItem],
        searchText: String,
        cuisine: Cuisine,
        maxDistanceKm: Double,
        limit: Int
    ) -> [Recommendation]
}

struct FMRecommendationService: RecommendationServiceProtocol {
    func recommend(
        preferences: UserPreferences,
        items: [FoodItem],
        searchText: String,
        cuisine: Cuisine,
        maxDistanceKm: Double,
        limit: Int
    ) -> [Recommendation] {

        // Map String arrays from UserPreferences -> typed sets (drop unknowns safely)
        let prefAllergens: Set<Allergen> =
            Set(preferences.allergies.compactMap(Allergen.init(rawValue:)))
        let prefDiet: Set<DietaryTag> =
            Set(preferences.dietaryPreferences.compactMap(DietaryTag.init(rawValue:)))
        let prefReligious: Set<ReligiousRule> =
            Set(preferences.religiousRules.compactMap(ReligiousRule.init(rawValue:)))

        // 1) Strict filtering (allergens, religious rules, distance, cuisine, search)
        let base: [FoodItem] = items.filter { item in
            // Exclude anything containing user allergens
            guard prefAllergens.isDisjoint(with: item.allergens) else { return false }
            // Must respect religious rules selected (empty set means no constraint)
            guard prefReligious.isSubset(of: item.religiousCompliance) else { return false }
            // Distance
            guard item.distanceKm <= maxDistanceKm else { return false }
            // Cuisine (All = wildcard)
            if cuisine != .all && item.cuisine != cuisine { return false }
            // Search
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                let hit = item.name.lowercased().contains(q) || item.restaurant.lowercased().contains(q)
                if !hit { return false }
            }
            return true
        }

        // 2) Score items by preference alignment & confidence
        // tuple: (item, score, isNearMatch)
        let scored: [(FoodItem, Double, Bool)] = base.map { item in
            // Diet alignment
            let dietIntersect = prefDiet.intersection(item.tags)
            let matchesAllDiet = prefDiet.isSubset(of: item.tags)

            var score: Double = 0
            // Preference alignment
            score += Double(dietIntersect.count) * 2.0
            if matchesAllDiet { score += 2.0 }
            // Confidence: penalize uncertain ingredients
            if item.uncertainIngredients { score -= 1.2 }
            // Utility: rating & distance
            score += item.rating * 0.25
            score += max(0, (5.0 - item.distanceKm)) * 0.15

            // Near match jika tidak memenuhi semua diet atau ada ketidakpastian
            let isNearMatch = (!matchesAllDiet) || item.uncertainIngredients
            return (item, score, isNearMatch)
        }

        // 3) Pisahkan strict vs near
        let strictMatches = scored.filter { !$0.2 }
        let nearMatches = scored.filter { $0.2 }

        // 4) Pilih list: prefer strict, jika kosong ambil near
        let chosen: ArraySlice<(FoodItem, Double, Bool)>
        if strictMatches.isEmpty {
            chosen = nearMatches.sorted { $0.1 > $1.1 }.prefix(limit)
        } else {
            chosen = strictMatches.sorted { $0.1 > $1.1 }.prefix(limit)
        }

        // 5) Build Recommendation + reason singkat
        let recs: [Recommendation] = chosen.map { (item, score, isNear) in
            let dietaryTags = item.tags.map(\.rawValue).sorted().joined(separator: ", ")
            let religiousTags = item.religiousCompliance.map(\.rawValue).sorted().joined(separator: ", ")
            let distance = String(format: "%.1f", item.distanceKm)
            let rating = String(format: "%.1f", item.rating)

            let reason: String = {
                if isNear {
                    return "Near match: aligns with your preferences (\(religiousTags)). Rated \(rating) and \(distance) km away."
                } else {
                    return "Matches your preferences (\(religiousTags); \(dietaryTags)). Rated \(rating) and \(distance) km away."
                }
            }()

            return Recommendation(item: item, score: score, reason: reason, isNearMatch: isNear)
        }

        return recs
    }
}
