//import Foundation
//import Combine
//import FoundationModels
//
//final class HomeViewModel: ObservableObject {
//    // Inputs
//    @Published var searchText: String = ""
//    @Published var selectedCuisine: Cuisine = .all
//    @Published var maxDistanceKm: Double = 5.0
//    @Published var selectedDietaryFilters: Set<DietaryTag> = []
//    @Published var onlyStrictSafe: Bool = false
//    
//    // Data
//    @Published private(set) var preferences: UserPreferences
//    @Published private(set) var allItems: [FoodItem] = []
//    @Published private(set) var filteredItems: [FoodItem] = []
//    @Published private(set) var recommendations: [Recommendation] = []
//    
//    private let prefsRepo: PreferencesRepositoryProtocol
//    private let foodRepo: FoodRepositoryProtocol
//    private var cancellables: Set<AnyCancellable> = []
//    private let recommender: RecommendationServiceProtocol = FMRecommendationService()
//    
//    
//    // FoundationModels
//    private let instructions: String = """
//              You are an assistant that selects suitable food options strictly from a provided candidate list.
//              Your goal is to identify choices that align with the user's HEALTH profile and current LOCATION constraints.
//   
//              OUTPUT FORMAT
//              - Output MUST be a JSON array of FoodRecommendationItem (Generable schema).
//              - No extra commentary, no markdown, no explanations—ONLY the JSON array.
//   
//              CANDIDATE POLICY
//              - Do NOT invent restaurants or items not present in the candidates.
//              - Prioritize items with safety status STRICT_SAFE, then SAFE.
//              - Exclude anything marked uncertain when strict mode is ON.
//   
//              HEALTH & SAFETY RULES
//              - Exclude any item that violates allergies, religious rules, or hard dietary restrictions.
//              - Give preference to items matching dietary preferences and avoiding listed nutrients (e.g., low-sodium, no added sugar).
//              - Never override or relax allergy or religion-related constraints.
//   
//              LOCATION RULES
//              - Only include items whose candidate distance_m is ≤ the user's maximum distance (in meters).
//              - Copy distanceMeters from candidate distance_m exactly.
//   
//              FIELD CONSTRAINTS (Generable)
//              - name: short, human-readable, 2–60 chars.
//              - locationName: short, human-readable.
//              - rating: copy from candidate (0.0–5.0).
//              - distanceMeters: copy candidate distance_m (meters).
//              - matchMessage: ONE concise sentence (≤140 chars), no emojis. Mention the key health or location reason when relevant.
//              - tags: up to 5 concise tags; prefer existing candidate tags; add at most one new tag if essential.
//   
//              SELECTION & ORDERING
//              - Return at most 5 items.
//              - Order by: (1) compliance with strict mode & health constraints, (2) higher rating, (3) nearer distance.
//   
//              VALIDATION
//              - If no candidate satisfies strict mode, return an empty array.
//              - Ensure every returned item is present in candidates and follows all constraints.
//   """
//    var languageModelSession: LanguageModelSession?
//    @Published private(set) var aiRecommendations: [FoodRecommendationItem] = []
//    
//    
//    init(
//        prefsRepo: PreferencesRepositoryProtocol = PreferencesRepository(),
//        foodRepo: FoodRepositoryProtocol = FoodRepository()
//    ) {
//        self.prefsRepo = prefsRepo
//        self.foodRepo = foodRepo
//        self.preferences = prefsRepo.loadPreferences()
//        self.allItems = foodRepo.loadFoodItems()
//        self.selectedDietaryFilters = preferences.dietaryPreferences
//        bind()
//        applyFilters()
//        
//        setupLanguageModel()
//    }
//    func setupLanguageModel(){
//        languageModelSession = LanguageModelSession(instructions: instructions)
//        print("Language model setup complete.")
//    }
//    
//    /// Builds a compact, LLM-friendly text table of candidate items.
//    private func candidateContext(limit: Int = 20) -> String {
//        let source = filteredItems.isEmpty ? allItems : filteredItems
//        let items = Array(source.prefix(limit))
//        
//        // Keep it terse; the model just needs grounding facts.
//        let lines = items.map { item -> String in
//            let status = safetyStatus(for: item)
//            let reason = reasonText(for: item)
//            let tagsLine = item.tags.map { "\($0)" }.joined(separator: ", ")
//            // Distances are in KM in your repo — convert so the model can copy meters directly.
//            let meters = Int((item.distanceKm * 1000).rounded())
//            return [
//                "name=\(item.name)",
//                "restaurant=\(item.restaurant)",
//                "cuisine=\(item.cuisine.rawValue)",
//                "rating=\(String(format: "%.1f", item.rating))",
//                "distance_m=\(meters)",
//                "safety=\(status)",
//                "tags=[\(tagsLine)]",
//                "reason=\(reason)"
//            ].joined(separator: " | ")
//        }
//        
//        return lines.joined(separator: "\n")
//    }
//    /// Creates a focused prompt that asks ONLY for the Generable schema.
//    private func buildRecommendationPrompt(limit: Int = 5, city: String) -> Prompt {
//        let dietarySelected = selectedDietaryFilters.map(\.rawValue).sorted().joined(separator: ", ")
//        let dietPrefs = preferences.dietaryPreferences.map(\.rawValue).sorted().joined(separator: ", ")
//        let allergies = preferences.allergies.map(\.rawValue).sorted().joined(separator: ", ")
//        let religious = preferences.religiousRules.map(\.rawValue).sorted().joined(separator: ", ")
//        let avoidNutrients = preferences.nutrientsToAvoid.map(\.rawValue).sorted().joined(separator: ", ")
//        
//        let candidates = candidateContext()
//        
//        return Prompt {
//              """
//              USER CONTEXT
//              - Search text: "\(searchText)"
//              - Selected cuisine: \(selectedCuisine.rawValue)
//              - Max distance (km): \(String(format: "%.1f", maxDistanceKm))
//              - Dietary filter chips (selected): [\(dietarySelected)]
//              - Preferences:
//                • Dietary: [\(dietPrefs)]
//                • Allergies: [\(allergies)]
//                • Religious rules: [\(religious)]
//                • Nutrients to avoid: [\(avoidNutrients)]
//              - Strict safe only: \(onlyStrictSafe ? "YES" : "NO")
//              
//              CANDIDATES (do not invent beyond these)
//              \(candidates)
//              
//              Produce only the JSON array of FoodRecommendationItem.
//              
//              LOCATION: \(city)
//              """
//        }
//    }
//    
//    /// Generates AI-grounded recommendations and publishes them to `aiRecommendations`.
//    @MainActor
//    func generateFoodRecommendation(limit: Int = 5, city: String) async {
//        guard let languageModelSession else { return }
//        
//        
//        do {
//            let prompt = buildRecommendationPrompt(limit: limit, city: city)
//            print(prompt)
//            let result = try await languageModelSession.respond(to: prompt, generating: [FoodRecommendationItem].self)
//            
//            // Normalize + publish
//            let items = result.content.map { $0.normalized() }
//            self.aiRecommendations = items
//            print("AI recommendations (\(items.count)):", items)
//        } catch {
//            // Non-fatal logging; keep the app responsive.
//            print("generateFoodRecommendation error:", error.localizedDescription)
//            self.aiRecommendations = []
//        }
//    }
//    
//    private func bind() {
//        Publishers.CombineLatest3($searchText, $selectedCuisine, $maxDistanceKm)
//            .merge(with: $selectedDietaryFilters.map { _ in (self.searchText, self.selectedCuisine, self.maxDistanceKm) })
//            .merge(with: $onlyStrictSafe.map { _ in (self.searchText, self.selectedCuisine, self.maxDistanceKm) })
//            .sink { [weak self] _ in
//                self?.applyFilters()
//            }
//            .store(in: &cancellables)
//    }
//    
//    func safetyStatus(for item: FoodItem) -> SafetyStatus {
//        let hasAllergen = !preferences.allergies.isDisjoint(with: item.allergens)
//        let matchesAllDietary = preferences.dietaryPreferences.isSubset(of: item.tags)
//        let matchesAnyDietary = !preferences.dietaryPreferences.isEmpty && !preferences.dietaryPreferences.isDisjoint(with: item.tags)
//        let respectsReligion = preferences.religiousRules.isSubset(of: item.religiousCompliance)
//        let avoidsNutrients = preferences.nutrientsToAvoid.isDisjoint(with: item.nutrients)
//        
//        if hasAllergen { return .checkDetails }
//        if respectsReligion && matchesAllDietary && avoidsNutrients && !item.uncertainIngredients {
//            return .strictSafe
//        }
//        if respectsReligion && (matchesAllDietary || matchesAnyDietary) && avoidsNutrients {
//            return item.uncertainIngredients ? .checkDetails : .safe
//        }
//        return .checkDetails
//    }
//    
//    func reasonText(for item: FoodItem) -> String {
//        let status = safetyStatus(for: item)
//        switch status {
//        case .strictSafe: return "Fully matches your preferences and avoids allergens."
//        case .safe: return "Good match with minor considerations."
//        case .checkDetails: return "Ingredients uncertain — review details."
//        }
//    }
//    
//    func applyFilters() {
//        let base = allItems.filter { item in
//            // Exclude allergens always
//            guard preferences.allergies.isDisjoint(with: item.allergens) else { return false }
//            // Cuisine
//            if selectedCuisine != .all && item.cuisine != selectedCuisine { return false }
//            // Distance
//            if item.distanceKm > maxDistanceKm { return false }
//            // Search
//            if !searchText.isEmpty {
//                let query = searchText.lowercased()
//                if !(item.name.lowercased().contains(query) || item.restaurant.lowercased().contains(query)) { return false }
//            }
//            // Dietary filter chips: when set, require intersection
//            if !selectedDietaryFilters.isEmpty && selectedDietaryFilters.isDisjoint(with: item.tags) { return false }
//            
//            // Religious rules: must respect selected preferences
//            if !preferences.religiousRules.isSubset(of: item.religiousCompliance) { return false }
//            
//            // Nutrients to avoid: if strict-only, exclude items containing avoided nutrients
//            if onlyStrictSafe && !preferences.nutrientsToAvoid.isDisjoint(with: item.nutrients) { return false }
//            
//            return true
//        }
//        
//        let refined = base.filter { item in
//            if onlyStrictSafe { return safetyStatus(for: item) == .strictSafe }
//            return true
//        }
//        
//        filteredItems = refined.sorted { a, b in
//            // Sort by safety, rating, then distance
//            let sa = safetyStatus(for: a)
//            let sb = safetyStatus(for: b)
//            if sa != sb { return sa == .strictSafe }
//            if a.rating != b.rating { return a.rating > b.rating }
//            return a.distanceKm < b.distanceKm
//        }
//        computeRecommendations()
//    }
//    
//    private func computeRecommendations() {
//        let recs = recommender.recommend(
//            preferences: preferences,
//            items: allItems,
//            searchText: searchText,
//            cuisine: selectedCuisine,
//            maxDistanceKm: maxDistanceKm,
//            limit: 3
//        )
//        self.recommendations = recs
//    }
//    
//}
//
//
//extension FoodRecommendationItem {
//    /// Safety net: clean tags and clamp ranges.
//    func normalized() -> FoodRecommendationItem {
//        let cleanedTags = tags
//            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
//            .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) }
//            .filter { !$0.isEmpty }
//            .uniqued()
//            .prefix(5)
//        
//        let clampedRating = max(0.0, min(5.0, rating))
//        let clampedDistance = max(0.0, min(50_000.0, distanceMeters)) // meters
//        
//        return FoodRecommendationItem(
//            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
//            locationName: locationName.trimmingCharacters(in: .whitespacesAndNewlines),
//            rating: clampedRating,
//            distanceMeters: clampedDistance,
//            matchMessage: matchMessage.trimmingCharacters(in: .whitespacesAndNewlines),
//            tags: Array(cleanedTags)
//        )
//    }
//}
//
//private extension Sequence where Element: Hashable {
//    func uniqued() -> [Element] {
//        var seen = Set<Element>()
//        return filter { seen.insert($0).inserted }
//    }
//}

import Foundation
import Combine
import SwiftData
import FoundationModels

// MARK: - Typed view-facing preferences (enum-based)
struct TypedPreferences {
    var name: String?
    var city: String?
    var allergies: Set<Allergen>
    var dietaryPreferences: Set<DietaryTag>
    var religiousRules: Set<ReligiousRule>
    var isOnboarded: Bool

    init(model m: UserPreferences) {
        self.name = m.name
        self.city = m.city
        self.allergies = Set(m.allergies.compactMap(Allergen.init(rawValue:)))
        self.dietaryPreferences = Set(m.dietaryPreferences.compactMap(DietaryTag.init(rawValue:)))
        self.religiousRules = Set(m.religiousRules.compactMap(ReligiousRule.init(rawValue:)))
        self.isOnboarded = m.isOnboarded
    }
}

// MARK: - HomeViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    // Inputs
    @Published var searchText: String = ""
    @Published var selectedCuisine: Cuisine = .all
    @Published var maxDistanceKm: Double = 5.0
    @Published var selectedDietaryFilters: Set<DietaryTag> = []
    @Published var onlyStrictSafe: Bool = false

    // Data (UI-facing & model)
    @Published private(set) var preferences: TypedPreferences
    private(set) var preferencesModel: UserPreferences

    @Published private(set) var allItems: [FoodItem] = []
    @Published private(set) var filteredItems: [FoodItem] = []
    @Published private(set) var recommendations: [Recommendation] = []

    // Services
    private let prefsRepo: PreferencesRepositoryProtocol
    private let foodRepo: FoodRepositoryProtocol
    private let recommender: RecommendationServiceProtocol = FMRecommendationService()

    // LLM session (optional)
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
    @Published var isLoadingRecommendations: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Designated init (inject repositories)
    init(prefsRepo: PreferencesRepositoryProtocol, foodRepo: FoodRepositoryProtocol) {
        self.prefsRepo = prefsRepo
        self.foodRepo = foodRepo

        // Load model from repo → map ke typed
        let model = prefsRepo.loadPreferences()
        self.preferencesModel = model
        self.preferences = TypedPreferences(model: model)

        // Data
        self.allItems = foodRepo.loadFoodItems()
        self.selectedDietaryFilters = preferences.dietaryPreferences

        bind()
        applyFilters()
        setupLanguageModel()
    }

    // MARK: - Convenience init (pakai SwiftData context langsung)
    convenience init(context: ModelContext, foodRepo: FoodRepositoryProtocol = FoodRepository()) {
        let repo = PreferencesRepository(context: context)
        self.init(prefsRepo: repo, foodRepo: foodRepo)
    }

    // MARK: - Convenience init (pakai prefs yang sudah dimiliki View)
    convenience init(prefs: UserPreferences, foodRepo: FoodRepositoryProtocol = FoodRepository()) {
        struct StaticRepo: PreferencesRepositoryProtocol {
            let seed: UserPreferences
            func loadPreferences() -> UserPreferences { seed }
        }
        self.init(prefsRepo: StaticRepo(seed: prefs), foodRepo: foodRepo)
    }

    // MARK: - LLM
    func setupLanguageModel() {
        languageModelSession = LanguageModelSession(instructions: instructions)
    }

    private func candidateContext(limit: Int = 20) -> String {
        let source = filteredItems.isEmpty ? allItems : filteredItems
        let items = Array(source.prefix(limit))
        let lines = items.map { item -> String in
            let status = safetyStatus(for: item)
            let reason = reasonText(for: item)
            let tagsLine = item.tags.map { "\($0.rawValue)" }.joined(separator: ", ")
            let meters = Int((item.distanceKm * 1000).rounded())
            return [
                "name=\(item.name)",
                "restaurant=\(item.restaurant)",
                "cuisine=\(item.cuisine.rawValue)",
                "rating=\(String(format: "%.1f", item.rating))",
                "distance_m=\(meters)",
                "safety=\(status.rawValue)",
                "tags=[\(tagsLine)]",
                "reason=\(reason)"
            ].joined(separator: " | ")
        }
        return lines.joined(separator: "\n")
    }

    private func buildRecommendationPrompt(limit: Int = 5, city: String) -> Prompt {
        let dietarySelected = selectedDietaryFilters.map(\.rawValue).sorted().joined(separator: ", ")
        let dietPrefs = preferences.dietaryPreferences.map(\.rawValue).sorted().joined(separator: ", ")
        let allergies = preferences.allergies.map(\.rawValue).sorted().joined(separator: ", ")
        let religious = preferences.religiousRules.map(\.rawValue).sorted().joined(separator: ", ")
        let candidates = candidateContext()
        
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
              - Strict safe only: \(onlyStrictSafe ? "YES" : "NO")
              
              Produce only the JSON array of FoodRecommendationItem.
              
              LOCATION: \(city)
              """
        }
    }

    @MainActor
    func generateFoodRecommendation(limit: Int = 5, city: String) async {
        guard let languageModelSession else { return }
        isLoadingRecommendations = true
        defer { isLoadingRecommendations = false }
        do {
            let prompt = buildRecommendationPrompt(limit: limit, city: city)
            let result = try await languageModelSession.respond(to: prompt, generating: [FoodRecommendationItem].self)
            let items = result.content.map { $0.normalized() }
            self.aiRecommendations = items
        } catch {
            print("generateFoodRecommendation error:", error.localizedDescription)
            self.aiRecommendations = []
        }
    }

    // MARK: - Bind & Filters
    private func bind() {
        Publishers.CombineLatest3($searchText, $selectedCuisine, $maxDistanceKm)
            .merge(with: $selectedDietaryFilters.map { _ in (self.searchText, self.selectedCuisine, self.maxDistanceKm) })
            .merge(with: $onlyStrictSafe.map { _ in (self.searchText, self.selectedCuisine, self.maxDistanceKm) })
            .sink { [weak self] _ in self?.applyFilters() }
            .store(in: &cancellables)
    }

    func safetyStatus(for item: FoodItem) -> SafetyStatus {
        let hasAllergen = !preferences.allergies.isDisjoint(with: item.allergens)
        let respectsReligion = preferences.religiousRules.isSubset(of: item.religiousCompliance)

        // Dietary: match all (strict) atau any (relaxed)
        let matchesAllDietary = preferences.dietaryPreferences.isSubset(of: item.tags)
        let matchesAnyDietary = !preferences.dietaryPreferences.isEmpty
                               && !preferences.dietaryPreferences.isDisjoint(with: item.tags)

        if hasAllergen { return .checkDetails }
        if respectsReligion && matchesAllDietary && !item.uncertainIngredients {
            return .strictSafe
        }
        if respectsReligion && (matchesAllDietary || matchesAnyDietary) {
            return item.uncertainIngredients ? .checkDetails : .safe
        }
        return .checkDetails
    }

    func reasonText(for item: FoodItem) -> String {
        switch safetyStatus(for: item) {
        case .strictSafe:    return "Fully matches your preferences and avoids allergens."
        case .safe:          return "Good match with minor considerations."
        case .checkDetails:  return "Ingredients uncertain — review details."
        }
    }

    func applyFilters() {
        let base = allItems.filter { item in
            // 1) Always exclude allergens
            guard preferences.allergies.isDisjoint(with: item.allergens) else { return false }
            // 2) Cuisine
            if selectedCuisine != .all && item.cuisine != selectedCuisine { return false }
            // 3) Distance
            if item.distanceKm > maxDistanceKm { return false }
            // 4) Search
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                if !(item.name.lowercased().contains(q) || item.restaurant.lowercased().contains(q)) { return false }
            }
            // 5) Dietary filter chips (when selected, require intersection)
            if !selectedDietaryFilters.isEmpty && selectedDietaryFilters.isDisjoint(with: item.tags) { return false }
            // 6) Religious rules must be respected
            if !preferences.religiousRules.isSubset(of: item.religiousCompliance) { return false }

            return true
        }

        let refined = base.filter { item in
            onlyStrictSafe ? (safetyStatus(for: item) == .strictSafe) : true
        }

        filteredItems = refined.sorted { a, b in
            let sa = safetyStatus(for: a)
            let sb = safetyStatus(for: b)
            if sa != sb { return sa == .strictSafe }        // strictSafe first
            if a.rating != b.rating { return a.rating > b.rating }
            return a.distanceKm < b.distanceKm
        }

        computeRecommendations()
    }

    private func computeRecommendations() {
        // Recommender kamu sebelumnya menerima UserPreferences -> tetap pakai model aslinya
        let recs = recommender.recommend(
            preferences: preferencesModel,
            items: allItems,
            searchText: searchText,
            cuisine: selectedCuisine,
            maxDistanceKm: maxDistanceKm,
            limit: 3
        )
        self.recommendations = recs
    }
}

// MARK: - LLM sanitation
extension FoodRecommendationItem {
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

extension HomeViewModel {
    @MainActor
    func reloadFromStore(using context: ModelContext) {
        let repo = PreferencesRepository(context: context)
        let fresh = repo.loadPreferences()
        self.preferencesModel = fresh
        self.preferences = TypedPreferences(model: fresh)
        self.selectedDietaryFilters = preferences.dietaryPreferences
        applyFilters()
    }
}
