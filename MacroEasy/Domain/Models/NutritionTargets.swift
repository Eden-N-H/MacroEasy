//
//  NutritionTargets.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

struct NutritionTargets: MacronutrientProviding {
    var goal: NutritionGoal
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double
    var calories: Double
}
