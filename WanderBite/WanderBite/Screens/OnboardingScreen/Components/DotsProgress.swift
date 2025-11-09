//
//  DotsProgress.swift
//  WanderBite
//
//  Created by Shafa Tiara Tsabita Himawan on 09/11/25.
//

import SwiftUI

struct DotsProgress: View {
    let current: Int
    let total: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .foregroundStyle(i == current ? .primary : .secondary)
                    .opacity(i == current ? 1 : 0.3)
                    .frame(width: i == current ? 10 : 6, height: i == current ? 10 : 6)
            }
        }
        .padding(.vertical, 6)
    }
}
