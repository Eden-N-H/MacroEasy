//
//  CalculateDailyNutritionProgressUseCase.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

//  CalculateDailyNutritionProgressUseCase.swift

import Foundation


struct MacroProgress {
    let macro: Macronutrient
    let consumedGrams: Double
    let targetGrams: Double


    var progressFraction: Double {
        guard targetGrams > 0 else { return 0 }
        return min(consumedGrams / targetGrams, 2.0)
    }
}


struct DailyNutritionProgress {
    let date: Date
    let caloriesConsumed: Double
    let caloriesTarget: Double
    let macroProgress: [MacroProgress]
    let entries: [MealEntry]
    let mealsMissingMacros: Int

   
    var hasIncompleteMacroData: Bool {
        mealsMissingMacros > 0
    }
}


struct CalculateDailyNutritionProgressUseCase {
    private let repository: NutritionRepository

    init(repository: NutritionRepository) {
        self.repository = repository
    }

    func execute(for date: Date = Date()) throws -> DailyNutritionProgress {
        let targets: NutritionTargets?
        do {
            targets = try repository.fetchNutritionTargets()
        } catch {
            throw CalculateDailyNutritionProgressError.dataUnavailable
        }

        guard let targets else {
            throw CalculateDailyNutritionProgressError.noTargetsConfigured
        }

        let entries: [MealEntry]
        do {
            entries = try repository.fetchMealEntries(on: date)
        } catch {
            throw CalculateDailyNutritionProgressError.dataUnavailable
        }

        let caloriesConsumed = entries.reduce(0) { $0 + $1.calories }
        let proteinConsumed = entries.reduce(0) { $0 + $1.proteinGrams }
        let carbConsumed = entries.reduce(0) { $0 + $1.carbGrams }
        let fatConsumed = entries.reduce(0) { $0 + $1.fatGrams }

        let macroProgress = [
            MacroProgress(macro: .protein, consumedGrams: proteinConsumed, targetGrams: targets.proteinGrams),
            MacroProgress(macro: .carbohydrate, consumedGrams: carbConsumed, targetGrams: targets.carbGrams),
            MacroProgress(macro: .fat, consumedGrams: fatConsumed, targetGrams: targets.fatGrams)
        ]

        let mealsMissingMacros = entries.filter { !$0.macrosProvided }.count

        return DailyNutritionProgress(
            date: date,
            caloriesConsumed: caloriesConsumed,
            caloriesTarget: targets.calories,
            macroProgress: macroProgress,
            entries: entries,
            mealsMissingMacros: mealsMissingMacros
        )
    }
}

enum CalculateDailyNutritionProgressError: LocalizedError {
    case noTargetsConfigured
    case dataUnavailable

    var errorDescription: String? {
        switch self {
        case .noTargetsConfigured:
            return "Set your daily goals first so we can show your progress."
        case .dataUnavailable:
            return "We couldn't load today's meals right now. Please try again."
        }
    }
}
