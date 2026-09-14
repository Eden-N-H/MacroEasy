//
//  NutritionRepository.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

protocol NutritionRepository {

    @discardableResult
    func insertMealEntry(_ entry: MealEntry) throws -> MealEntry
    func fetchMealEntries(on date: Date) throws -> [MealEntry]
    func fetchMealEntries(from startDate: Date, to endDate: Date) throws -> [MealEntry]
    func deleteMealEntry(id: Int64) throws


    @discardableResult
    func saveMealTemplate(_ meal: SavedMeal) throws -> SavedMeal
    func fetchSavedMeals() throws -> [SavedMeal]
    func deleteSavedMeal(id: Int64) throws


    func fetchNutritionTargets() throws -> NutritionTargets?
    func saveNutritionTargets(_ targets: NutritionTargets) throws
}


enum RepositoryError: LocalizedError {
    case connectionFailed
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Could not connect to the local database."
        case .operationFailed(let detail):
            return "Database operation failed: \(detail)"
        }
    }
}
