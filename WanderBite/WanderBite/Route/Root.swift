//
//  Root.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \UserPreferences.createdAt, order: .forward)
    private var prefs: [UserPreferences]

    var body: some View {
        Group {
            if let p = prefs.first, p.isOnboarded {
                HomeView(prefs: p)
            } else {
                OnboardingFlowView()
            }
        }
    }
}




