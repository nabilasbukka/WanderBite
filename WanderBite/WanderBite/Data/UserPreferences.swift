//
//  SwiftData.swift
//  
//
//  Created by Shafa Tiara Tsabita Himawan on 08/11/25.
//

import Foundation
import SwiftData

@Model
final class UserPreferences {
    @Attribute(.unique) var id: String = "singleton-userprefs"
    var createdAt: Date = Date()
    
    var name: String?
    var city: String?
    
    var allergies: [String]
    var dietaryPreferences: [String]
    var religiousRules: [String]
    
    var isOnboarded: Bool

    init(
        name: String = "",
        city: String = "",

        allergies: [String] = [],
        dietaryPreferences: [String] = [],
        religiousRules: [String] = [],
         
         
        isOnboarded: Bool = true) {
            self.name = name
            self.city = city
            self.allergies = allergies
            self.dietaryPreferences = dietaryPreferences
            self.religiousRules = religiousRules
            
            
            self.isOnboarded = isOnboarded
        }
}
