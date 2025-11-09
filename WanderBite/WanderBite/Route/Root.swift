//
//  Root.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \UserPreferences.createdAt) private var prefs: [UserPreferences]

    var body: some View {
        if let p = prefs.first, p.isOnboarded {
            HomeView(prefs: p)
        } else {
            OnboardingFlowView()
        }
    }
}

struct HomeView: View {
    let prefs: UserPreferences
    var body: some View {
        NavigationStack {
            List {
                if let name = prefs.name, !name.isEmpty { LabeledContent("Name", value: name) }
                if let city = prefs.city, !city.isEmpty { LabeledContent("City", value: city) }

                Section("Your Profile") {
                    LabeledContent("Allergies", value: prefs.allergies.joined(separator: ", "))
                    LabeledContent("Diet", value: prefs.dietaryPreferences.joined(separator: ", "))
                    LabeledContent("Rules", value: prefs.religiousRules.joined(separator: ", "))
                }
            }
            .navigationTitle("Home")
        }
    }
}



