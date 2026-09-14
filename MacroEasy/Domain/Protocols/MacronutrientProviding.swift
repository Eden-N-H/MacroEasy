//
//  MacronutrientProviding.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

protocol MacronutrientProviding {
    var proteinGrams: Double { get }
    var carbGrams: Double { get }
    var fatGrams: Double { get }
    var calories: Double { get }
}

extension MacronutrientProviding {
    var impliedCalories: Double {
        (proteinGrams * Macronutrient.protein.caloriesPerGram)
        + (carbGrams * Macronutrient.carbohydrate.caloriesPerGram)
        + (fatGrams * Macronutrient.fat.caloriesPerGram)
    }

    func isCalorieConsistent(tolerance: Double = 0.10) -> Bool {
        guard impliedCalories > 0 else { return calories == 0 }
        let difference = abs(calories - impliedCalories) / impliedCalories
        return difference <= tolerance
    }
}
