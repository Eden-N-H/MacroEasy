//
//  MockNutritionRepository.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation
@testable import MacroEasy

final class MockNutritionRepository: NutritionRepository {
    private var mealEntries: [MealEntry] = []
    private var savedMealsStorage: [SavedMeal] = []
    private var targets: NutritionTargets?
    private var nextMealID: Int64 = 1
    private var nextSavedMealID: Int64 = 1

    @discardableResult
    func insertMealEntry(_ entry: MealEntry) throws -> MealEntry {
        let saved = MealEntry(
            id: nextMealID,
            dishName: entry.dishName,
            mealType: entry.mealType,
            loggedAt: entry.loggedAt,
            proteinGrams: entry.proteinGrams,
            carbGrams: entry.carbGrams,
            fatGrams: entry.fatGrams,
            calories: entry.calories,
            macrosProvided: entry.macrosProvided
        )
        nextMealID += 1
        mealEntries.append(saved)
        return saved
    }

    func fetchMealEntries(on date: Date) throws -> [MealEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        return try fetchMealEntries(from: startOfDay, to: endOfDay)
    }

    func fetchMealEntries(from startDate: Date, to endDate: Date) throws -> [MealEntry] {
        mealEntries.filter { $0.loggedAt >= startDate && $0.loggedAt < endDate }
    }

    func deleteMealEntry(id: Int64) throws {
        mealEntries.removeAll { $0.id == id }
    }

    @discardableResult
    func saveMealTemplate(_ meal: SavedMeal) throws -> SavedMeal {
        let saved = SavedMeal(
            id: nextSavedMealID,
            dishName: meal.dishName,
            proteinGrams: meal.proteinGrams,
            carbGrams: meal.carbGrams,
            fatGrams: meal.fatGrams,
            calories: meal.calories,
            macrosProvided: meal.macrosProvided
        )
        nextSavedMealID += 1
        savedMealsStorage.append(saved)
        return saved
    }

    func fetchSavedMeals() throws -> [SavedMeal] {
        savedMealsStorage
    }

    func deleteSavedMeal(id: Int64) throws {
        savedMealsStorage.removeAll { $0.id == id }
    }

    func fetchNutritionTargets() throws -> NutritionTargets? {
        targets
    }

    func saveNutritionTargets(_ targets: NutritionTargets) throws {
        self.targets = targets
    }
}
