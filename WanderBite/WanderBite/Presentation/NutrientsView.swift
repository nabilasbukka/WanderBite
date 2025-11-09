//
//  NutrientsView.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import SwiftUI

struct NutrientsStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        Form {
            Section(
                header: Text("Nutrients to avoid / limit"),
                footer: Text("We’ll use this to filter foods and show safer alternatives.")
            ) {
                ForEach(Nutrient.allCases, id: \.rawValue) { item in
                    Toggle(item.rawValue,
                           isOn: Binding(
                            get: { vm.selectedNutrients.contains(item.rawValue) },
                            set: { newVal in
                                if newVal { vm.selectedNutrients.insert(item.rawValue) }
                                else { vm.selectedNutrients.remove(item.rawValue) }
                            })
                    )
                }
                TextField("Other nutrient (optional)", text: $vm.customNutrient)
                    .textInputAutocapitalization(.words)
            }
        }
        .navigationTitle(OnboardingStep.nutrients.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
