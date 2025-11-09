//
//  CulturalView.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import SwiftUI

struct CulturalRulesStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        Form {
            Section("Select rules that apply") {
                ForEach(CulturalRule.allCases, id: \.rawValue) { item in
                    Toggle(item.rawValue,
                           isOn: Binding(
                            get: { vm.selectedCultural.contains(item.rawValue) },
                            set: { newVal in
                                if newVal { vm.selectedCultural.insert(item.rawValue) }
                                else { vm.selectedCultural.remove(item.rawValue) }
                            })
                    )
                }
                TextField("Other rule (optional)", text: $vm.customCultural)
                    .textInputAutocapitalization(.words)
            }
        }
        .navigationTitle(OnboardingStep.culture.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
