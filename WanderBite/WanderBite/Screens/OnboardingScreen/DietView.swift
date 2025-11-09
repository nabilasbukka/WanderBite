//
//  DietView.swift
//  WanderBite
//
//  Created by Shafa Tiara Tsabita Himawan on 09/11/25.
//

import SwiftUI
import Observation

struct OnboardingDietView: View {
    @Bindable var vm: OnboardingViewModel
    private let grid = [GridItem(.adaptive(minimum: 180), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(OnboardingStep.diet.title).font(.title2.bold())
            LazyVGrid(columns: grid, spacing: 10) {
                ForEach(DietaryTag.allCases) { tag in
                    PillChip(
                        label: tag.rawValue,
                        isSelected: vm.selectedDietTags.contains(tag)
                    ) { vm.toggle(tag, in: &vm.selectedDietTags) }
                }
            }
        }
        .padding(.horizontal)
    }
}
