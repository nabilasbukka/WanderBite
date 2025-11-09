//
//  AllergenView.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import SwiftUI

struct AllergensStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        Form {
            Section("List of allergens") {
                ForEach(Allergens.allCases, id: \.rawValue) { item in
                    Toggle(item.label,
                           isOn: Binding(
                            get: { vm.selectedAllergens.contains(item.rawValue) },
                            set: { newVal in
                                if newVal { vm.selectedAllergens.insert(item.rawValue) }
                                else { vm.selectedAllergens.remove(item.rawValue) }
                            })
                    )
                }
                TextField("Other allergen (optional)", text: $vm.customAllergen)
                    .textInputAutocapitalization(.words)
            }
        }
        .navigationTitle(OnboardingStep.allergens.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
