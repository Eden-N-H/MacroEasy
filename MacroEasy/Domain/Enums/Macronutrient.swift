//
//  Macronutrient.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

enum Macronutrient: String, CaseIterable, Identifiable {
    case protein
    case carbohydrate
    case fat
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .protein: return "Protein"
        case .carbohydrate: return "Carbs"
        case .fat: return "Fat"
        }
    }

    var caloriesPerGram: Double {
        switch self {
        case .protein, .carbohydrate: return 4.0
        case .fat: return 9.0
        }
    }
}

