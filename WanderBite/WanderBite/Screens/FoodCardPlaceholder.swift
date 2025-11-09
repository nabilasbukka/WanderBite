import SwiftUI

struct FoodCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.12))
                .frame(height: 120)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 28))
                        .foregroundStyle(.teal)
                        .opacity(0.4)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Text placeholders
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 16)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 14)
                    .padding(.trailing, 80)
            }
            
            // Tags row placeholder
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 70, height: 26)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            FoodCardPlaceholder()
            FoodCardPlaceholder()
            FoodCardPlaceholder()
        }
        .padding()
    }
}

