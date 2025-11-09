//
//  OnboardingViewModel.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import Foundation
import SwiftData
import Combine

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case allergens, diet, culture, nutrients
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .allergens: return "Food Allergies"
        case .diet:      return "Dietary Preferences"
        case .culture:   return "Cultural / Religious Rules"
        case .nutrients: return "Nutrients to Avoid/Limit"
        }
    }
}

enum Allergens: String, CaseIterable {
    case milk, eggs, fish, crustaceanShellfish = "crustacean shellfish",
         treeNuts = "tree nuts", peanuts, wheat, soybeans, sesame
    var label: String { rawValue.capitalized }
}

enum DietPref: String, CaseIterable {
    case pescatarian = "Pescatarian", vegan = "Vegan", paleo = "Paleo",
         ovoVegetarian = "Ovo-Vegetarian", glutenFree = "Gluten Free Diet",
         ketogenic = "Ketogenic Diet", dairyFree = "Dairy / Lactose Free Diet"
}

enum CulturalRule: String, CaseIterable {
    case kosher = "Kosher", halal = "Halal"
}

enum Nutrient: String, CaseIterable {
    case sodium = "Sodium", sugar = "Sugar", saturatedFat = "Saturated Fat",
         transFat = "Trans Fat", cholesterol = "Cholesterol", calories = "Calories"
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var selectedAllergens: Set<String> = []
    @Published var selectedDiet: Set<String> = []
    @Published var selectedCultural: Set<String> = []
    @Published var selectedNutrients: Set<String> = []

    @Published var customAllergen: String = ""
    @Published var customDiet: String = ""
    @Published var customCultural: String = ""
    @Published var customNutrient: String = ""

    @Published var step: OnboardingStep = .allergens
    var canGoNext: Bool { true }

    func goNext() { if let next = OnboardingStep(rawValue: step.rawValue + 1) { step = next } }
    func goBack() { if let prev = OnboardingStep(rawValue: step.rawValue - 1) { step = prev } }

    func finalizeSelections() {
        addIfNotEmpty(customAllergen, to: &selectedAllergens)
        addIfNotEmpty(customDiet, to: &selectedDiet)
        addIfNotEmpty(customCultural, to: &selectedCultural)
        addIfNotEmpty(customNutrient, to: &selectedNutrients)
    }

    private func addIfNotEmpty(_ text: String, to set: inout Set<String>) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { set.insert(trimmed) }
    }

    func save(context: ModelContext) throws {
        finalizeSelections()
        let profile = OnboardingProfile(
            allergies: Array(selectedAllergens).sorted(),
            dietPreferences: Array(selectedDiet).sorted(),
            culturalRules: Array(selectedCultural).sorted(),
            nutrientLimits: Array(selectedNutrients).sorted(),
            isOnboarded: true
        )
        context.insert(profile)
        try context.save()
    }
}
