//
//  ContainerView.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var context
    @StateObject var vm = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(vm.step.rawValue + 1),
                             total: Double(OnboardingStep.allCases.count))
                .padding(.horizontal)
                .padding(.top, 8)

                Group {
                    switch vm.step {
                    case .allergens: AllergensStepView(vm: vm)
                    case .diet:      DietStepView(vm: vm)
                    case .culture:   CulturalRulesStepView(vm: vm)
                    case .nutrients: NutrientsStepView(vm: vm)
                    }
                }
                .animation(.default, value: vm.step)

                HStack {
                    Button("Back") { vm.goBack() }
                        .buttonStyle(.bordered)
                        .disabled(vm.step == .allergens)

                    Spacer()

                    if vm.step == .nutrients {
                        Button("Finish") {
                            do {
                                try vm.save(context: context)
                            } catch {
                                print("SwiftData save error: \(error)")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Next") { vm.goNext() }
                            .buttonStyle(.borderedProminent)
                            .disabled(!vm.canGoNext)
                    }
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle("Onboarding")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
