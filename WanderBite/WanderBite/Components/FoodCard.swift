import SwiftUI

struct FoodCard: View {
    let item: FoodRecommendationItem
    @State private var isLoading: Bool = false
    @State private var imageURL: URL?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                // Placeholder image
                ZStack {
                    
                    Group {
                        if isLoading {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.12))
                            Image(systemName: "fork.knife")
                                .font(.system(size: 36))
                                .foregroundStyle(.teal)
                            //                            ProgressView()
                            //                                .progressViewStyle(.circular)
                            //                                .scaleEffect(1.5)
                        } else if let imageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: 350)
                                        .cornerRadius(8)
                                        .shadow(radius: 4)
                                case .failure:
                                    Text("Failed to load image.")
                                        .foregroundColor(.red)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                        } else {
                            Text("No results found.")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    
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
        
        .onAppear {
            Task {
                await load()
            }
        }
    }
    
    
    
    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        imageURL = nil
        do {
            let url = try await UnsplashService.shared.searchFirstPhoto(query: item.name)
            imageURL = url
            print("query = \(item.name)")
            print("image url from unsplash \(imageURL)")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
}

