//
//  OnboardingView.swift
//  WanderBite
//
//  Created by Shafa Tiara Tsabita Himawan on 09/11/25.
//

import SwiftUI
import SwiftData
import Observation

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var context
    @State private var haptic = UIImpactFeedbackGenerator(style: .soft)
    @State var vm = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                CuteBackground()

                VStack(spacing: 18) {
                    header

                    ZStack {
                        Cute.glass(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        TabView(selection: $vm.step) {
                            OnboardingAllergiesView(vm: vm).tag(OnboardingStep.allergens)
                            OnboardingDietView(vm: vm).tag(OnboardingStep.diet)
                            OnboardingCulturalRulesView(vm: vm).tag(OnboardingStep.culture)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .padding(18)
                    }
                    .padding(.horizontal)
                    .animation(.snappy(duration: 0.28), value: vm.step)
                }
                .safeAreaInset(edge: .bottom) { bottomBar }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Let’s eat healthy")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Cute.accent)
                    .shadow(radius: 0)
            }
            Text(subtitle(for: vm.step))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .transition(.opacity)
            DotsProgress(current: vm.step.rawValue, total: OnboardingStep.allCases.count)
                .animation(.snappy, value: vm.step)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private func subtitle(for step: OnboardingStep) -> String {
        switch step {
        case .allergens: return "Pick allergens to avoid."
        case .diet:      return "Choose what fits your lifestyle."
        case .culture:   return "Respect your rules & beliefs."
        }
    }
    
    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                haptic.impactOccurred()
                vm.goBack()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .disabled(vm.step == .allergens)

            Spacer()

            if vm.step == .culture {
                Button {
                    haptic.impactOccurred()
                    do { try vm.save(context: context) } catch { print("Save error:", error) }
                } label: { Text("Finish") }
                .buttonStyle(PrimaryCapsuleButtonStyle())
                .disabled(!vm.canGoNext)
            } else {
                Button {
                    haptic.impactOccurred()
                    vm.goNext()
                } label: { Text("Next") }
                .buttonStyle(PrimaryCapsuleButtonStyle())
                .disabled(!vm.canGoNext)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(Divider().opacity(0.4), alignment: .top)
    }
}
