//
//  WanderBiteApp.swift
//  WanderBite
//
//  Created by Nabila Putri Syafrina Bukka on 08/11/25.
//

import SwiftUI
import SwiftData

@main
struct WanderBiteApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: UserPreferences.self)
    }
}
