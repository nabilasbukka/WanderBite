//
//  Root.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \OnboardingProfile.createdAt) private var profiles: [OnboardingProfile]

    var body: some View {
        if let profile = profiles.first, profile.isOnboarded {
            HomeView(profile: profile)
        } else {
            OnboardingFlowView()
        }
    }
}

struct HomeView: View {
    let profile: OnboardingProfile
    var body: some View {
        NavigationStack {
            List {
                Section("Your Profile") {
                    LabeledContent("Allergies", value: profile.allergies.joined(separator: ", "))
                    LabeledContent("Diet", value: profile.dietPreferences.joined(separator: ", "))
                    LabeledContent("Cultural Rules", value: profile.culturalRules.joined(separator: ", "))
                    LabeledContent("Nutrients", value: profile.nutrientLimits.joined(separator: ", "))
                }
            }
            .navigationTitle("Home")
        }
    }
}

