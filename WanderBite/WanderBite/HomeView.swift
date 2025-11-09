import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @StateObject private var locViewModel = CityLocationViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    private var activePreferenceChips: [String] {
        var chips: [String] = []
        chips.append(contentsOf: vm.preferences.religiousRules.map { $0.rawValue })
        chips.append(contentsOf: vm.preferences.dietaryPreferences.map { $0.rawValue })
        chips.append(contentsOf: vm.preferences.allergies.map { "\($0.rawValue)-Free" })
        return chips
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    topAppBar
                    heroSection
                    filterBar
                    suggestionsSection
                    //foodListSection
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await vm.generateFoodRecommendation(city: "Osaka")
                }
            }
        }
    }
    
    private var topAppBar: some View {
        HStack {
            Text("Find Food for Your Trip")
                .font(.title3.bold())
            Spacer()
        }
        .padding(.top)
    }
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hi, Traveler 👋 – Safe picks near you in \(locViewModel.city)")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(activePreferenceChips, id: \.self) { title in
                        FilterChip(title: title, isSelected: true) {}
                    }
                }
            }
            
            Button(action: {}) {
                Label("Edit Preferences", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.bordered)
            .tint(.teal)
            .accessibilityLabel("Edit preferences")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color.teal.opacity(0.15) : Color.teal.opacity(0.1))
        )
    }
    
    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search meals or places", text: $vm.searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            
            // Cuisine chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Cuisine.allCases, id: \.self) { cuisine in
                        FilterChip(title: cuisine.rawValue, isSelected: vm.selectedCuisine == cuisine) {
                            vm.selectedCuisine = cuisine
                        }
                    }
                }
            }
            
            // Dietary filters chips
            VStack(alignment: .leading, spacing: 6) {
                Text("Dietary filters")
                    .font(.subheadline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(vm.preferences.dietaryPreferences), id: \.self) { tag in
                            let isOn = vm.selectedDietaryFilters.contains(tag)
                            FilterChip(title: tag.rawValue, isSelected: isOn) {
                                if isOn { vm.selectedDietaryFilters.remove(tag) } else { vm.selectedDietaryFilters.insert(tag) }
                            }
                        }
                    }
                }
            }
            
            Toggle("Only Strict-Safe", isOn: $vm.onlyStrictSafe)
                .tint(.teal)
                .accessibilityLabel("Toggle only strict safe items")
        }
    }
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) { // <- leading alignment
            Text("Top Picks for You")
                .font(.headline)
                .multilineTextAlignment(.leading) // <- align text left
            
            VStack(spacing: 12) {
                ForEach(vm.aiRecommendations, id: \.id) { rec in
                    NavigationLink {
                        FoodDetailView(item: rec)
                    } label: {
                        FoodCard(item: rec)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    /*
     private var foodListSection: some View {
     Group {
     if vm.filteredItems.isEmpty {
     VStack(spacing: 12) {
     Text("No safe meals found nearby.")
     .font(.headline)
     Button("Relax Filters") {
     vm.selectedDietaryFilters.removeAll()
     vm.onlyStrictSafe = false
     vm.searchText = ""
     }
     .buttonStyle(.borderedProminent)
     .tint(.teal)
     }
     .frame(maxWidth: .infinity)
     .padding()
     .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
     } else {
     LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12, alignment: .center)], alignment: .center, spacing: 12) {
     ForEach(vm.filteredItems) { item in
     let safety = vm.safetyStatus(for: item)
     NavigationLink {
     FoodDetailView(item: item, safety: safety)
     } label: {
     FoodCard(item: item, safety: safety, reasonText: vm.reasonText(for: item))
     .frame(maxWidth: .infinity, alignment: .center)
     }
     .buttonStyle(.plain)
     }
     }
     }
     }
     }*/
}

#Preview {
    HomeView()
}
