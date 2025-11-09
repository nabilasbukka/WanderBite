//
//  AllergiesView.swift
//  WanderBite
//
//  Created by Shafa Tiara Tsabita Himawan on 09/11/25.
//

import SwiftUI
import Observation

struct OnboardingAllergiesView: View {
    @Bindable var vm: OnboardingViewModel
    private let grid = [GridItem(.adaptive(minimum: 160), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(OnboardingStep.allergens.title).font(.title2.bold())
            LazyVGrid(columns: grid, spacing: 10) {
                ForEach(Allergen.allCases) { allergen in
                    PillChip(
                        label: allergen.rawValue,
                        isSelected: vm.selectedAllergens.contains(allergen)
                    ) { vm.toggle(allergen, in: &vm.selectedAllergens) }
                }
            }
        }
        .padding(.horizontal)
    }
}

