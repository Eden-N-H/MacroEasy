//
//  MealEntry.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

struct MealEntry: Identifiable, MacronutrientProviding {
    let id: Int64
    var dishName: String
    var mealType: MealType
    var loggedAt: Date
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double
    var calories: Double
}
