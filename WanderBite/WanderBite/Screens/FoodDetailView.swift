import SwiftUI

struct FoodDetailView: View {
//    let item: FoodItem
//    let safety: SafetyStatus
    let item: FoodRecommendationItem
    
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
                
                //SafetyBadge(status: safety)
                
                Text(item.name)
                    .font(.title2.bold())
                Text(item.matchMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(item.tags.joined(separator: ", "))
                
                Text("Placeholder for ingredients, allergen info, and navigation.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        //.accessibilityLabel("Details for \(item.name) at \(item.restaurant). Safety: \(safety.rawValue).")
    }
}

#Preview {
    NavigationStack {
        FoodDetailView(
            item: FoodRecommendationItem(name: "Miso Soup", matchMessage: "Good for you", tags: ["vegan", "halal"])
            
            
        )
    }
}
