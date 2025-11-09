import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    // Inputs
    @Published var searchText: String = ""
    @Published var selectedCuisine: Cuisine = .all
    @Published var maxDistanceKm: Double = 5.0
    @Published var selectedDietaryFilters: Set<DietaryTag> = []
    @Published var onlyStrictSafe: Bool = false
    
    // Data
    @Published private(set) var preferences: UserPreferences
    @Published private(set) var allItems: [FoodItem] = []
    @Published private(set) var filteredItems: [FoodItem] = []
    @Published private(set) var recommendations: [Recommendation] = []

    private let prefsRepo: PreferencesRepositoryProtocol
    private let foodRepo: FoodRepositoryProtocol
    private var cancellables: Set<AnyCancellable> = []
    private let recommender: RecommendationServiceProtocol = FMRecommendationService()
    
    init(
        prefsRepo: PreferencesRepositoryProtocol = PreferencesRepository(),
        foodRepo: FoodRepositoryProtocol = FoodRepository()
    ) {
        self.prefsRepo = prefsRepo
        self.foodRepo = foodRepo
        self.preferences = prefsRepo.loadPreferences()
        self.allItems = foodRepo.loadFoodItems()
        self.selectedDietaryFilters = preferences.dietaryPreferences
        bind()
        applyFilters()
    }
    
    private func bind() {
        Publishers.CombineLatest3($searchText, $selectedCuisine, $maxDistanceKm)
            .merge(with: $selectedDietaryFilters.map { _ in (self.searchText, self.selectedCuisine, self.maxDistanceKm) })
            .merge(with: $onlyStrictSafe.map { _ in (self.searchText, self.selectedCuisine, self.maxDistanceKm) })
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    func safetyStatus(for item: FoodItem) -> SafetyStatus {
        let hasAllergen = !preferences.allergies.isDisjoint(with: item.allergens)
        let matchesAllDietary = preferences.dietaryPreferences.isSubset(of: item.tags)
        let matchesAnyDietary = !preferences.dietaryPreferences.isEmpty && !preferences.dietaryPreferences.isDisjoint(with: item.tags)
        let respectsReligion = preferences.religiousRules.isSubset(of: item.religiousCompliance)
        let avoidsNutrients = preferences.nutrientsToAvoid.isDisjoint(with: item.nutrients)
        
        if hasAllergen { return .checkDetails }
        if respectsReligion && matchesAllDietary && avoidsNutrients && !item.uncertainIngredients {
            return .strictSafe
        }
        if respectsReligion && (matchesAllDietary || matchesAnyDietary) && avoidsNutrients {
            return item.uncertainIngredients ? .checkDetails : .safe
        }
        return .checkDetails
    }
    
    func reasonText(for item: FoodItem) -> String {
        let status = safetyStatus(for: item)
        switch status {
        case .strictSafe: return "Fully matches your preferences and avoids allergens."
        case .safe: return "Good match with minor considerations."
        case .checkDetails: return "Ingredients uncertain — review details."
        }
    }
    
    func applyFilters() {
        let base = allItems.filter { item in
            // Exclude allergens always
            guard preferences.allergies.isDisjoint(with: item.allergens) else { return false }
            // Cuisine
            if selectedCuisine != .all && item.cuisine != selectedCuisine { return false }
            // Distance
            if item.distanceKm > maxDistanceKm { return false }
            // Search
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                if !(item.name.lowercased().contains(query) || item.restaurant.lowercased().contains(query)) { return false }
            }
            // Dietary filter chips: when set, require intersection
            if !selectedDietaryFilters.isEmpty && selectedDietaryFilters.isDisjoint(with: item.tags) { return false }
            
            // Religious rules: must respect selected preferences
            if !preferences.religiousRules.isSubset(of: item.religiousCompliance) { return false }
            
            // Nutrients to avoid: if strict-only, exclude items containing avoided nutrients
            if onlyStrictSafe && !preferences.nutrientsToAvoid.isDisjoint(with: item.nutrients) { return false }
            
            return true
        }
        
        let refined = base.filter { item in
            if onlyStrictSafe { return safetyStatus(for: item) == .strictSafe }
            return true
        }
        
        filteredItems = refined.sorted { a, b in
            // Sort by safety, rating, then distance
            let sa = safetyStatus(for: a)
            let sb = safetyStatus(for: b)
            if sa != sb { return sa == .strictSafe }
            if a.rating != b.rating { return a.rating > b.rating }
            return a.distanceKm < b.distanceKm
        }
        computeRecommendations()
    }
    
    private func computeRecommendations() {
        let recs = recommender.recommend(
            preferences: preferences,
            items: allItems,
            searchText: searchText,
            cuisine: selectedCuisine,
            maxDistanceKm: maxDistanceKm,
            limit: 3
        )
        self.recommendations = recs
    }
    
}