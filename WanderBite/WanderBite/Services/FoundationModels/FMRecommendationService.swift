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
        // 1) Filter out strict violations first (allergens, religious rules, distance, cuisine, search)
        let base = items.filter { item in
            guard preferences.allergies.isDisjoint(with: item.allergens) else { return false }
            guard preferences.religiousRules.isSubset(of: item.religiousCompliance) else { return false }
            guard item.distanceKm <= maxDistanceKm else { return false }
            if cuisine != .all && item.cuisine != cuisine { return false }
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                if !(item.name.lowercased().contains(q) || item.restaurant.lowercased().contains(q)) { return false }
            }
            return true
        }

        // 2) Score items based on preference alignment and confidence
        let scored: [(FoodItem, Double, Bool)] = base.map { item in
            let dietaryIntersection = preferences.dietaryPreferences.intersection(item.tags)
            let matchesAllDietary = preferences.dietaryPreferences.isSubset(of: item.tags)
            let avoidsNutrients = preferences.nutrientsToAvoid.isDisjoint(with: item.nutrients)
            let uncertain = item.uncertainIngredients

            var score: Double = 0
            // Preference alignment
            score += Double(dietaryIntersection.count) * 2.0
            if matchesAllDietary { score += 2.0 }
            if avoidsNutrients { score += 1.2 }
            // Confidence adjustments
            if uncertain { score -= 1.5 }
            // Utility features
            score += item.rating * 0.25
            score += max(0, (5.0 - item.distanceKm)) * 0.15
            
            // Near match if it doesn't meet all dietary prefs or has minor nutrient overlap (but still passed strict filter above)
            let isNearMatch = !matchesAllDietary || !avoidsNutrients || uncertain
            return (item, score, isNearMatch)
        }

        // 3) Partition strict matches vs near matches
        let strictMatches = scored.filter { !$0.2 }
        let nearMatches = scored.filter { $0.2 }

        // 4) Choose list: prefer strict; otherwise near matches
        let chosenList: [(FoodItem, Double, Bool)]
        if strictMatches.isEmpty {
            // No perfect matches, present near matches with clear note
            chosenList = nearMatches.sorted { $0.1 > $1.1 }.prefix(limit).map { $0 }
        } else {
            chosenList = strictMatches.sorted { $0.1 > $1.1 }.prefix(limit).map { $0 }
        }

        // 5) Generate short, traveler-friendly reasons (1–2 sentences)
        let recommendations: [Recommendation] = chosenList.map { (item, score, isNear) in
            let dietaryTags = Array(item.tags).map { $0.rawValue }.joined(separator: ", ")
            let religiousTags = Array(item.religiousCompliance).map { $0.rawValue }.joined(separator: ", ")
            let distance = String(format: "%.1f", item.distanceKm)
            let rating = String(format: "%.1f", item.rating)
            let baseReason: String
            if isNear {
                baseReason = "Near match: aligns with your preferences (\(religiousTags)). Rated \(rating) and \(distance) km away."
            } else {
                baseReason = "Matches your preferences (\(religiousTags); \(dietaryTags)). Rated \(rating) and \(distance) km away."
            }
            let reason = baseReason
            return Recommendation(item: item, score: score, reason: reason, isNearMatch: isNear)
        }

        return recommendations
    }
}