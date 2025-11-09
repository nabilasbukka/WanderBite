import SwiftUI

struct FoodCard: View {
    let item: FoodItem
    let safety: SafetyStatus
    let reasonText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                // Placeholder image
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.12))
                    Image(systemName: "fork.knife")
                        .font(.system(size: 36))
                        .foregroundStyle(.teal)
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                SafetyBadge(status: safety)
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                Text(item.restaurant)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 8) {
                Label("\(String(format: "%.1f", item.rating))", systemImage: "star.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", item.rating))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 0)
                
                Label("\(item.distanceKm, specifier: "%.1f") km", systemImage: "mappin.and.ellipse")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            // Tags row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(item.tags), id: \.self) { tag in
                        FilterChip(title: tag.rawValue, isSelected: true) {}
                    }
                    ForEach(Array(item.religiousCompliance), id: \.self) { rule in
                        FilterChip(title: rule.rawValue, isSelected: true) {}
                    }
                }
            }
            
            Text(reasonText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name) at \(item.restaurant), safety: \(safety.rawValue), rating \(item.rating), distance \(item.distanceKm) km")
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Save") {}.tint(.teal)
            Button("Not for me") {}.tint(.gray)
        }
    }
}

#Preview {
    let item = FoodItem(
        name: "Test Dish",
        restaurant: "Test Place",
        cuisine: .local,
        distanceKm: 1.0,
        rating: 4.5,
        tags: [.glutenFree, .pescatarian],
        allergens: [],
        religiousCompliance: [.halal],
        nutrients: [],
        description: "",
        imageName: nil
    )
    return FoodCard(item: item, safety: .strictSafe, reasonText: "Fully matches your preferences.")
        .padding()
}