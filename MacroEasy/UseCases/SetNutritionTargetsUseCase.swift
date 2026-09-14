//
//  SetNutritionTargetsUseCase.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//
//  SetNutritionTargetsUseCase.swift

import Foundation


struct SetNutritionTargetsUseCase {
    private let repository: NutritionRepository

    init(repository: NutritionRepository) {
        self.repository = repository
    }

    @discardableResult
    func execute(
        goal: NutritionGoal,
        calories: Double,
        proteinGrams: Double,
        carbGrams: Double,
        fatGrams: Double
    ) throws -> NutritionTargets {
        guard calories > 0 else {
            throw SetNutritionTargetsError.invalidCalorieTarget
        }

        guard proteinGrams >= 0, carbGrams >= 0, fatGrams >= 0 else {
            throw SetNutritionTargetsError.invalidMacroAmount
        }

        let targets = NutritionTargets(
            goal: goal,
            proteinGrams: proteinGrams,
            carbGrams: carbGrams,
            fatGrams: fatGrams,
            calories: calories
        )

        guard targets.isCalorieConsistent() else {
            throw SetNutritionTargetsError.calorieMismatch(
                statedCalories: calories,
                expectedCalories: targets.impliedCalories
            )
        }

        do {
            try repository.saveNutritionTargets(targets)
            return targets
        } catch {
            throw SetNutritionTargetsError.persistenceFailed(error.localizedDescription)
        }
    }

    
    static func suggestedMacros(for goal: NutritionGoal, calories: Double) -> (proteinGrams: Double, carbGrams: Double, fatGrams: Double) {
        let split = goal.defaultMacroSplit
        let proteinGrams = (calories * split.proteinPercent) / Macronutrient.protein.caloriesPerGram
        let carbGrams = (calories * split.carbPercent) / Macronutrient.carbohydrate.caloriesPerGram
        let fatGrams = (calories * split.fatPercent) / Macronutrient.fat.caloriesPerGram
        return (proteinGrams, carbGrams, fatGrams)
    }
}

enum SetNutritionTargetsError: LocalizedError {
    case invalidCalorieTarget
    case invalidMacroAmount
    case calorieMismatch(statedCalories: Double, expectedCalories: Double)
    case persistenceFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCalorieTarget:
            return "Please enter a calorie goal greater than zero."
        case .invalidMacroAmount:
            return "Macro targets can't be negative. Check your numbers and try again."
        case .calorieMismatch(let stated, let expected):
            return "Your calorie goal (\(Int(stated))) doesn't match what your protein, carb and fat targets add up to (about \(Int(expected))). Adjust one of these so they line up."
        case .persistenceFailed:
            return "Something went wrong saving your goals. Please try again."
        }
    }
}
