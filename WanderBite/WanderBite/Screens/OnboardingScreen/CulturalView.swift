//
//  CulturalView.swift
//  WanderBite
//
//  Created by Shafa Tiara Tsabita Himawan on 09/11/25.
//

import SwiftUI
import Observation

struct OnboardingCulturalRulesView: View {
    @Bindable var vm: OnboardingViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(OnboardingStep.culture.title).font(.title2.bold())
            HStack(spacing: 10) {
                ForEach(ReligiousRule.allCases) { rule in
                    PillChip(
                        label: rule.rawValue,
                        isSelected: vm.selectedReligiousRule == rule
                    ) {
                        vm.selectedReligiousRule = (vm.selectedReligiousRule == rule) ? nil : rule
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
