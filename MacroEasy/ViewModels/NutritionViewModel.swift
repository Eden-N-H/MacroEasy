//
//  NutritionViewModel.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.


import Foundation
import Combine

final class NutritionViewModel: ObservableObject {
    @Published var dailyProgress: DailyNutritionProgress?
    @Published var targets: NutritionTargets?
    @Published var savedMeals: [SavedMeal] = []
    @Published var insights: [DietaryInsight] = []
    @Published var needsTargets: Bool = false
    @Published var errorMessage: String?

    private let repository: NutritionRepository
    private let logMealUseCase: LogMealUseCase
    private let setNutritionTargetsUseCase: SetNutritionTargetsUseCase
    private let calculateDailyNutritionProgressUseCase: CalculateDailyNutritionProgressUseCase
    private let assessMacronutrientAdequacyUseCase: AssessMacronutrientAdequacyUseCase
    private let generateDietaryInsightUseCase: GenerateDietaryInsightUseCase
    private let calculateNutritionHistoryUseCase: CalculateNutritionHistoryUseCase

    init(repository: NutritionRepository = SQLiteNutritionRepository()) {
        self.repository = repository
        self.logMealUseCase = LogMealUseCase(repository: repository)
        self.setNutritionTargetsUseCase = SetNutritionTargetsUseCase(repository: repository)
        self.calculateDailyNutritionProgressUseCase = CalculateDailyNutritionProgressUseCase(repository: repository)
        self.assessMacronutrientAdequacyUseCase = AssessMacronutrientAdequacyUseCase()
        self.generateDietaryInsightUseCase = GenerateDietaryInsightUseCase(repository: repository)
        self.calculateNutritionHistoryUseCase = CalculateNutritionHistoryUseCase(repository: repository)

        refreshDashboard()
    }

    // MARK: - Loading

    func refreshDashboard() {
        errorMessage = nil

        targets = try? repository.fetchNutritionTargets()

        do {
            dailyProgress = try calculateDailyNutritionProgressUseCase.execute()
            needsTargets = false
        } catch CalculateDailyNutritionProgressError.noTargetsConfigured {
            dailyProgress = nil
            needsTargets = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Could not load today's progress."
        }

        savedMeals = (try? repository.fetchSavedMeals()) ?? []

        // Insights need history — if there isn't enough yet, the section is
        // simply empty rather than showing an error on every launch.
        insights = (try? generateDietaryInsightUseCase.execute()) ?? []
    }

    // MARK: - Logging Meals

    func logMeal(
        dishName: String,
        mealType: MealType,
        calories: Double,
        proteinGrams: Double = 0,
        carbGrams: Double = 0,
        fatGrams: Double = 0
    ) {
        do {
            try logMealUseCase.execute(
                dishName: dishName,
                mealType: mealType,
                calories: calories,
                proteinGrams: proteinGrams,
                carbGrams: carbGrams,
                fatGrams: fatGrams
            )
            refreshDashboard()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Could not log this meal."
        }
    }

    func logSavedMeal(_ meal: SavedMeal, mealType: MealType) {
        logMeal(
            dishName: meal.dishName,
            mealType: mealType,
            calories: meal.calories,
            proteinGrams: meal.proteinGrams,
            carbGrams: meal.carbGrams,
            fatGrams: meal.fatGrams
        )
    }

    func deleteMeal(id: Int64) {
        do {
            try repository.deleteMealEntry(id: id)
            refreshDashboard()
        } catch {
            errorMessage = "Could not delete this meal."
        }
    }

    func saveAsTemplate(dishName: String, calories: Double, proteinGrams: Double, carbGrams: Double, fatGrams: Double) {
        let macrosProvided = proteinGrams > 0 || carbGrams > 0 || fatGrams > 0
        let meal = SavedMeal(
            id: 0,
            dishName: dishName,
            proteinGrams: proteinGrams,
            carbGrams: carbGrams,
            fatGrams: fatGrams,
            calories: calories,
            macrosProvided: macrosProvided
        )
        do {
            try repository.saveMealTemplate(meal)
            savedMeals = try repository.fetchSavedMeals()
        } catch {
            errorMessage = "Could not save this meal for later."
        }
    }

    // MARK: - Targets

    func setTargets(goal: NutritionGoal, calories: Double, proteinGrams: Double, carbGrams: Double, fatGrams: Double) {
        do {
            targets = try setNutritionTargetsUseCase.execute(
                goal: goal,
                calories: calories,
                proteinGrams: proteinGrams,
                carbGrams: carbGrams,
                fatGrams: fatGrams
            )
            refreshDashboard()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Could not save your goals."
        }
    }

    func suggestedMacros(for goal: NutritionGoal, calories: Double) -> (proteinGrams: Double, carbGrams: Double, fatGrams: Double) {
        SetNutritionTargetsUseCase.suggestedMacros(for: goal, calories: calories)
    }

    // MARK: - Macro Detail

    func adequacyAssessment(for macro: Macronutrient) -> MacronutrientAdequacyAssessment? {
        guard let progress = dailyProgress?.macroProgress.first(where: { $0.macro == macro }),
              let goal = targets?.goal else {
            return nil
        }
        return try? assessMacronutrientAdequacyUseCase.execute(macro: macro, progress: progress, goal: goal)
    }

    struct MacroMealBreakdown {
        let mealType: MealType
        let grams: Double
    }

    func gramsByMealType(for macro: Macronutrient) -> [MacroMealBreakdown] {
        guard let entries = dailyProgress?.entries else { return [] }
        let grouped = Dictionary(grouping: entries, by: \.mealType)

        return MealType.allCases.map { type in
            let grams = (grouped[type] ?? []).reduce(0.0) { sum, entry in
                switch macro {
                case .protein: return sum + entry.proteinGrams
                case .carbohydrate: return sum + entry.carbGrams
                case .fat: return sum + entry.fatGrams
                }
            }
            return MacroMealBreakdown(mealType: type, grams: grams)
        }
    }

    // MARK: - History

    func history(for range: HistoryTimeRange) -> [NutritionHistoryPoint] {
        (try? calculateNutritionHistoryUseCase.execute(range: range)) ?? []
    }
}
