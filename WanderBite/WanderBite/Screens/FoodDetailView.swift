import SwiftUI

struct FoodDetailView: View {
    let item: FoodItem
    let safety: SafetyStatus
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.12))
                        .frame(height: 180)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40))
                        .foregroundStyle(.teal)
                }
                
                SafetyBadge(status: safety)
                
                Text(item.name)
                    .font(.title2.bold())
                Text(item.restaurant)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Placeholder for ingredients, allergen info, and navigation.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityLabel("Details for \(item.name) at \(item.restaurant). Safety: \(safety.rawValue).")
    }
}

#Preview {
    NavigationStack {
        FoodDetailView(
            item: FoodItem(
                name: "Test Dish",
                restaurant: "Test Place",
                cuisine: .local,
                distanceKm: 1.0,
                rating: 4.5,
                tags: [.glutenFree],
                allergens: [],
                religiousCompliance: [.halal],
                nutrients: [],
                description: "",
                imageName: nil
            ),
            safety: .safe
        )
    }
}
