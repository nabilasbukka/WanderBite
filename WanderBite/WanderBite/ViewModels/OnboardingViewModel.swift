//
//  OnboardingViewModel.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import Foundation
import Observation
import SwiftData

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case allergens, diet, culture
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .allergens: return "What’s your allergy?"
        case .diet:      return "Your dietary preferences"
        case .culture:   return "Cultural / religious rules"
        }
    }
}

@Observable
final class OnboardingViewModel {
    var selectedAllergens: Set<Allergen> = []
    var selectedDietTags: Set<DietaryTag> = []
    var selectedReligiousRule: ReligiousRule? = nil
    
    private var editingTarget: UserPreferences?
    
    var step: OnboardingStep = .allergens
    var canGoNext: Bool {
        switch step {
        case .allergens: return true
        case .diet:      return true
        case .culture:   return selectedReligiousRule != nil
        }
    }
    
    init(seed: UserPreferences? = nil) {
        self.editingTarget = seed
        if let s = seed {
            self.selectedAllergens = Set(s.allergies.compactMap(Allergen.init(rawValue:)))
            self.selectedDietTags  = Set(s.dietaryPreferences.compactMap(DietaryTag.init(rawValue:)))
            self.selectedReligiousRule = s.religiousRules.compactMap(ReligiousRule.init(rawValue:)).first
        }
    }

    func toggle<T: Hashable>(_ value: T, in set: inout Set<T>) {
        if set.contains(value) { set.remove(value) } else { set.insert(value) }
    }
    func goNext() { if let n = OnboardingStep(rawValue: step.rawValue + 1) { step = n } }
    func goBack() { if let p = OnboardingStep(rawValue: step.rawValue - 1) { step = p } }

//    func save(context: ModelContext) throws {
//        let prefs = UserPreferences(
//            allergies: selectedAllergens.map(\.rawValue).sorted(),
//            dietaryPreferences: selectedDietTags.map(\.rawValue).sorted(),
//            religiousRules: selectedReligiousRule.map { [$0.rawValue] } ?? [],
//            isOnboarded: true
//        )
//        context.insert(prefs)
//        try context.save()
//    }
    func save(context: ModelContext) throws {
        let newAllergies = selectedAllergens.map(\.rawValue).sorted()
        let newDiet      = selectedDietTags.map(\.rawValue).sorted()
        let newRules     = selectedReligiousRule.map { [$0.rawValue] } ?? []

        if let target = editingTarget {
            target.allergies = newAllergies
            target.dietaryPreferences = newDiet
            target.religiousRules = newRules
            target.isOnboarded = true
            try context.save()
        } else {
            let prefs = UserPreferences(
                allergies: newAllergies,
                dietaryPreferences: newDiet,
                religiousRules: newRules,
                isOnboarded: true
            )
            context.insert(prefs)
            try context.save()
        }
    }
}
