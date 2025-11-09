//
//  CuteComponents.swift
//  WanderBite
//
//  Created by Shafa Tiara Tsabita Himawan on 09/11/25.
//

import SwiftUI

enum Cute {
    static let accent = LinearGradient(
        colors: [.pink, .orange],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let bg = LinearGradient(
        colors: [Color.mint.opacity(0.25), Color.teal.opacity(0.20)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static func glass<S: Shape>(_ shape: S) -> some View {
        shape.fill(.ultraThinMaterial)
            .overlay(shape.stroke(Color.white.opacity(0.25), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}

struct CuteBackground: View {
    var body: some View {
        ZStack {
            Cute.bg.ignoresSafeArea()
            Circle().fill(Color.pink.opacity(0.25)).frame(width: 300, height: 300)
                .blur(radius: 70).offset(x: -120, y: -220)
            Circle().fill(Color.cyan.opacity(0.22)).frame(width: 260, height: 260)
                .blur(radius: 70).offset(x: 150, y: 140)
        }
    }
}

struct PrimaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 22).padding(.vertical, 14)
            .background(Cute.accent, in: Capsule())
            .foregroundStyle(.white)
            .shadow(color: .pink.opacity(0.3), radius: 10, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}
