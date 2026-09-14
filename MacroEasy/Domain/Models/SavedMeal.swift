//
//  SavedMeal.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

struct SavedMeal: Identifiable, MacronutrientProviding {
    let id: Int64
    var dishName: String
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double
    var calories: Double
    var macrosProvided: Bool
}
