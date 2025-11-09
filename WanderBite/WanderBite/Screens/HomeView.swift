import SwiftUI

struct HomeView: View {
    @StateObject private var vm: HomeViewModel
    @StateObject private var locViewModel = CityLocationViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    
    @State private var showEdit = false
    
    init(prefs: UserPreferences) {
        _vm = StateObject(wrappedValue: HomeViewModel(prefs: prefs))
    }
    
    init(vm: HomeViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    private var activePreferenceChips: [String] {
        var chips: [String] = []
        chips.append(contentsOf: vm.preferences.religiousRules.map { $0.rawValue })
        chips.append(contentsOf: vm.preferences.dietaryPreferences.map { $0.rawValue })
        chips.append(contentsOf: vm.preferences.allergies.map { "\($0.rawValue)-Free" })
        return chips
    }
    
    // Consider the location "loading" while the city is still the placeholder.
    private var isCityLoading: Bool {
        locViewModel.city == "…"
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
                // If city already resolved when the view appears, fetch recommendations.
                if !isCityLoading {
                    Task { await vm.generateFoodRecommendation(city: locViewModel.city) }
                }
            }
            .onChange(of: locViewModel.city) { newCity in
                // When location resolves from "…" to a real city, fetch recommendations.
                guard newCity != "…" else { return }
                Task { await vm.generateFoodRecommendation(city: newCity) }
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
            if isCityLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Detecting your city…")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Detecting your city")
            } else {
                Text("Hi, Traveler 👋 – Safe picks near you in \(locViewModel.city)")
                    .font(.headline)
            }
            
            if !isCityLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(activePreferenceChips, id: \.self) { title in
                            FilterChip(title: title, isSelected: true) {}
                        }
                    }
                }
            } else {
                // Light placeholder row while loading city
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemFill))
                                .frame(width: 90, height: 30)
                                .redacted(reason: .placeholder)
                        }
                    }
                }
                .accessibilityHidden(true)
            }
            
            Button {
                showEdit = true
            } label: {
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
        .sheet(isPresented: $showEdit, onDismiss: {
            withAnimation(.snappy) {
                vm.reloadFromStore(using: context)
            }
            Task { await vm.generateFoodRecommendation(city: locViewModel.city) }
        }) {
            OnboardingFlowView(seed: vm.preferencesModel)
                .presentationDetents([.large])
        }
    }
    
    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search meals or places", text: $vm.searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .disabled(isCityLoading) // optional: disable while loading city
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .opacity(isCityLoading ? 0.6 : 1.0)
            
            // Cuisine chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Cuisine.allCases, id: \.self) { cuisine in
                        FilterChip(title: cuisine.rawValue, isSelected: vm.selectedCuisine == cuisine) {
                            vm.selectedCuisine = cuisine
                        }
                        .opacity(isCityLoading ? 0.6 : 1.0)
                        .allowsHitTesting(!isCityLoading)
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
                            .opacity(isCityLoading ? 0.6 : 1.0)
                            .allowsHitTesting(!isCityLoading)
                        }
                    }
                }
            }
            
            Toggle("Only Strict-Safe", isOn: $vm.onlyStrictSafe)
                .tint(.teal)
                .accessibilityLabel("Toggle only strict safe items")
                .disabled(isCityLoading)
                .opacity(isCityLoading ? 0.6 : 1.0)
        }
    }
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Picks for You")
                .font(.headline)
                .multilineTextAlignment(.leading)

            VStack(spacing: 12) {
                if isCityLoading {
                    // City still loading → show placeholders
                    ForEach(0..<3, id: \.self) { _ in
                        FoodCardPlaceholder()
                            .frame(maxWidth: .infinity)
                    }
                } else if vm.isLoadingRecommendations {
                    // Skeleton placeholders while loading recommendations
                    ForEach(0..<3, id: \.self) { _ in
                        FoodCardPlaceholder()
                            .frame(maxWidth: .infinity)
                    }
                } else if vm.aiRecommendations.isEmpty {
                    // Optional empty state
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No recommendations yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            Task { await vm.generateFoodRecommendation(city: locViewModel.city) }
                        } label: {
                            Label("Try Again", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .tint(.teal)
                        .disabled(isCityLoading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
                } else {
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
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
}
