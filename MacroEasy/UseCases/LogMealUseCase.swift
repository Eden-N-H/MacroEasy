//
//  LogMealUseCase.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

struct LogMealUseCase {
    private let repository: NutritionRepository

    init(repository: NutritionRepository) {
        self.repository = repository
    }

    @discardableResult
    func execute(
        dishName: String,
        mealType: MealType,
        loggedAt: Date = Date(),
        calories: Double,
        proteinGrams: Double = 0,
        carbGrams: Double = 0,
        fatGrams: Double = 0
    ) throws -> MealEntry {
        let trimmedName = dishName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw LogMealError.missingDishName
        }

        guard loggedAt <= Date() else {
            throw LogMealError.futureDateNotAllowed
        }

        guard calories >= 0, proteinGrams >= 0, carbGrams >= 0, fatGrams >= 0 else {
            throw LogMealError.invalidPortionAmount
        }

        let macrosProvided = proteinGrams > 0 || carbGrams > 0 || fatGrams > 0

        let draftEntry = MealEntry(
            id: 0,
            dishName: trimmedName,
            mealType: mealType,
            loggedAt: loggedAt,
            proteinGrams: proteinGrams,
            carbGrams: carbGrams,
            fatGrams: fatGrams,
            calories: calories,
            macrosProvided: macrosProvided
        )

        if macrosProvided {
            guard draftEntry.isCalorieConsistent() else {
                throw LogMealError.calorieMismatch(
                    loggedCalories: calories,
                    expectedCalories: draftEntry.impliedCalories
                )
            }
        }

        do {
            return try repository.insertMealEntry(draftEntry)
        } catch {
            throw LogMealError.persistenceFailed(error.localizedDescription)
        }
    }
}

enum LogMealError: LocalizedError {
    case missingDishName
    case futureDateNotAllowed
    case invalidPortionAmount
    case calorieMismatch(loggedCalories: Double, expectedCalories: Double)
    case persistenceFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingDishName:
            return "Please enter what you ate before saving."
        case .futureDateNotAllowed:
            return "You can't log a meal for a time that hasn't happened yet."
        case .invalidPortionAmount:
            return "Calories and macro amounts can't be negative. Check your entry and try again."
        case .calorieMismatch(let logged, let expected):
            return "The calories you entered (\(Int(logged))) don't match what your protein, carbs and fat add up to (about \(Int(expected))). Double check your numbers, or leave the macro fields blank if you're not sure."
        case .persistenceFailed:
            return "Something went wrong saving your meal. Please try again."
        }
    }
}
