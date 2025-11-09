//
//  DietView.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import SwiftUI

struct DietStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        Form {
            Section("List of dietary preferences") {
                ForEach(DietPref.allCases, id: \.rawValue) { item in
                    Toggle(item.rawValue,
                           isOn: Binding(
                            get: { vm.selectedDiet.contains(item.rawValue) },
                            set: { newVal in
                                if newVal { vm.selectedDiet.insert(item.rawValue) }
                                else { vm.selectedDiet.remove(item.rawValue) }
                            })
                    )
                }
                TextField("Other preference (optional)", text: $vm.customDiet)
                    .textInputAutocapitalization(.words)
            }
        }
        .navigationTitle(OnboardingStep.diet.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
