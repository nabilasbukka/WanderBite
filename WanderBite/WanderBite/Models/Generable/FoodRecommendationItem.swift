//
//  FoodRecommendationItem.swift
//  WanderBite
//
//  Created by Nabila Putri Syafrina Bukka on 09/11/25.
//

import Foundation
import FoundationModels

@Generable
struct FoodRecommendationItem {
    @Guide(description: "The restaurant or food item name, 2–60 characters.")
    let name: String

    @Guide(description: "Readable place label: mall, street, or neighborhood name.")
    let locationName: String

    // 0.0–5.0 rating, allow halves/decimals.
    @Guide(description: "Overall rating on a 0.0–5.0 scale.", .range(0.0...5.0))
    let rating: Double

    // Keep canonical unit in meters for sorting/filtering.
    @Guide(description: "Distance from the user in meters (non-negative).", .range(0.0...50_000.0))
    let distanceMeters: Double

    // Short human-friendly justification for why this is recommended.
    @Guide(description: "One-sentence reason this is a good match (≤140 chars).")
    let matchMessage: String

    // Up to 5 concise tags (singular nouns/adjectives), e.g. 'gluten-free', 'pasta', 'vegan'.
    @Guide(description: "Food tags, up to 5. Examples: 'gluten-free', 'pasta', 'vegan'.")
    let tags: [String]
}
