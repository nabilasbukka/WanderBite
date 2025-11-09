import Foundation
import Combine
import FoundationModels

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
    
    
    // FoundationModels
    private let instructions: String = """
   
            You are an assistant that generates a list of suitable food based on the user’s dietary preferences, restrictions, and LOCATION (given as a name only, without coordinates or distance data). Your goal is to suggest realistic food options that can typically be found or prepared in the given location, while strictly respecting user's dietary preference and restriction.
   
              OUTPUT FORMAT
              - Output MUST be a JSON array of FoodRecommendationItem (Generable schema).
              - No extra commentary, no markdown, no explanations—ONLY the JSON array.
   
              GENERATION CRITERIA
              - Exclude any item that violates allergies, religious restrictions, or strict dietary rules.
              - Prioritize foods that fit the user’s dietary preferences (e.g., vegetarian, halal, low-sodium, gluten-free).
              - Prefer nutritionally balanced or locally available dishes that meet the user’s health preferences.
              - Never override or relax allergy or religion-related constraints.
              - Generated list should reflect foods that are typical, distinctive, or culturally significant to the specified city (location).
              - Prioritize locally unique or signature foods that are not easily found elsewhere.
              - Avoid generic or globalized dishes unless no local options meet dietary rules.
   
              FIELD CONSTRAINTS (Generable)
              - name: short, human-readable, 2–60 chars of the food name.
              - matchMessage: ONE concise sentence (≤140 chars), no emojis. Mention the key health or reason when relevant.
              - tags: up to 5 concise tags; prefer existing candidate tags; add at most one new tag if essential.
   
              SELECTION & ORDERING
              - Return at most 5 items.
              - Order by compliance with strict mode & health constraints
   """
    var languageModelSession: LanguageModelSession?
    @Published private(set) var aiRecommendations: [FoodRecommendationItem] = []
    
    
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
        
        setupLanguageModel()
    }
    func setupLanguageModel(){
        languageModelSession = LanguageModelSession(instructions: instructions)
        print("Language model setup complete.")
    }
    
    /// Builds a compact, LLM-friendly text table of candidate items.
    private func candidateContext(limit: Int = 20) -> String {
        let source = filteredItems.isEmpty ? allItems : filteredItems
        let items = Array(source.prefix(limit))
        
        // Keep it terse; the model just needs grounding facts.
        let lines = items.map { item -> String in
            let status = safetyStatus(for: item)
            let reason = reasonText(for: item)
            let tagsLine = item.tags.map { "\($0)" }.joined(separator: ", ")
            // Distances are in KM in your repo — convert so the model can copy meters directly.
            let meters = Int((item.distanceKm * 1000).rounded())
            return [
                "name=\(item.name)",
                "restaurant=\(item.restaurant)",
                "cuisine=\(item.cuisine.rawValue)",
                "rating=\(String(format: "%.1f", item.rating))",
                "distance_m=\(meters)",
                "safety=\(status)",
                "tags=[\(tagsLine)]",
                "reason=\(reason)"
            ].joined(separator: " | ")
        }
        
        return lines.joined(separator: "\n")
    }
    /// Creates a focused prompt that asks ONLY for the Generable schema.
    private func buildRecommendationPrompt(limit: Int = 5, city: String) -> Prompt {
        let dietarySelected = selectedDietaryFilters.map(\.rawValue).sorted().joined(separator: ", ")
        let dietPrefs = preferences.dietaryPreferences.map(\.rawValue).sorted().joined(separator: ", ")
        let allergies = preferences.allergies.map(\.rawValue).sorted().joined(separator: ", ")
        let religious = preferences.religiousRules.map(\.rawValue).sorted().joined(separator: ", ")
        let avoidNutrients = preferences.nutrientsToAvoid.map(\.rawValue).sorted().joined(separator: ", ")
        
        //let candidates = candidateContext()
        
        return Prompt {
              """
              USER CONTEXT
              - Selected cuisine: \(selectedCuisine.rawValue)
              - Dietary filter chips (selected): [\(dietarySelected)]
              - Preferences:
                • Dietary: [\(dietPrefs)]
                • Allergies: [\(allergies)]
                • Religious rules: [\(religious)]
                • Nutrients to avoid: [\(avoidNutrients)]
              - Strict safe only: \(onlyStrictSafe ? "YES" : "NO")
              
              Produce only the JSON array of FoodRecommendationItem.
              
              LOCATION: \(city)
              """
        }
    }
    
    /// Generates AI-grounded recommendations and publishes them to `aiRecommendations`.
    @MainActor
    func generateFoodRecommendation(limit: Int = 5, city: String) async {
        guard let languageModelSession else { return }
        
        
        do {
            let prompt = buildRecommendationPrompt(limit: limit, city: city)
            print(prompt)
            let result = try await languageModelSession.respond(to: prompt, generating: [FoodRecommendationItem].self)
            
            // Normalize + publish
            let items = result.content.map { $0.normalized() }
            self.aiRecommendations = items
            print("AI recommendations (\(items.count)):", items)
        } catch {
            // Non-fatal logging; keep the app responsive.
            print("generateFoodRecommendation error:", error.localizedDescription)
            self.aiRecommendations = []
        }
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


extension FoodRecommendationItem {
    /// Safety net: clean tags and clamp ranges.
    func normalized() -> FoodRecommendationItem {
        let cleanedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) }
            .filter { !$0.isEmpty }
            .uniqued()
            .prefix(5)
        
//        let clampedRating = max(0.0, min(5.0, rating))
//        let clampedDistance = max(0.0, min(50_000.0, distanceMeters)) // meters
        
        return FoodRecommendationItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
//            locationName: locationName.trimmingCharacters(in: .whitespacesAndNewlines),
//            rating: clampedRating,
//            distanceMeters: clampedDistance,
            matchMessage: matchMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: Array(cleanedTags)
        )
    }
}

private extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
