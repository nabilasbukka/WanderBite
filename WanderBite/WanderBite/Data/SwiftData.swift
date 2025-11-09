//
//  SwiftData.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import Foundation
import SwiftData

@Model
final class OnboardingProfile {
    @Attribute(.unique) var id: String = "singleton-onboarding"
    var createdAt: Date = Date()
    var allergies: [String]
    var dietPreferences: [String]
    var culturalRules: [String]
    var nutrientLimits: [String]
    var isOnboarded: Bool

    init(allergies: [String] = [],
         dietPreferences: [String] = [],
         culturalRules: [String] = [],
         nutrientLimits: [String] = [],
         isOnboarded: Bool = true) {
        self.allergies = allergies
        self.dietPreferences = dietPreferences
        self.culturalRules = culturalRules
        self.nutrientLimits = nutrientLimits
        self.isOnboarded = isOnboarded
    }
}
