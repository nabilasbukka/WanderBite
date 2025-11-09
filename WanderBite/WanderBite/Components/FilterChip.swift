import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.footnote.weight(.semibold))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.teal.opacity(0.2) : Color.secondary.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.teal : Color.secondary.opacity(0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter: \(title) \(isSelected ? "selected" : "not selected")")
    }
}

#Preview {
    HStack {
        FilterChip(title: "Halal", isSelected: true) {}
        FilterChip(title: "Gluten-Free", isSelected: false) {}
    }
}