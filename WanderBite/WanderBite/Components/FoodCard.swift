import SwiftUI

struct FoodCard: View {
    let item: FoodRecommendationItem
    
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
                
//                SafetyBadge(status: safety)
//                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                Text(item.matchMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Tags row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(item.tags, id: \.self) { tag in
                        FilterChip(title: tag, isSelected: true) {}
                    }
                    
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
        .accessibilityElement(children: .combine)
        //.accessibilityLabel("\(item.name) at \(item.restaurant), safety: \(safety.rawValue), rating \(item.rating), distance \(item.distanceKm) km")
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Save") {}.tint(.teal)
            Button("Not for me") {}.tint(.gray)
        }
    }
}

