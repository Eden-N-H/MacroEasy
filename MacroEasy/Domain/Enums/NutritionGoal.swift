//
//  NutritionGoal.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

enum NutritionGoal: String, CaseIterable, Identifiable {
    case loseWeight
    case maintain
    case buildMuscle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .loseWeight: return "Lose Weight"
        case .maintain: return "Maintain"
        case .buildMuscle: return "Build Muscle"
        }
    }

 
    var defaultMacroSplit: (proteinPercent: Double, carbPercent: Double, fatPercent: Double) {
        switch self {
        case .loseWeight:  return (0.40, 0.30, 0.30)
        case .maintain:    return (0.30, 0.40, 0.30)
        case .buildMuscle: return (0.35, 0.40, 0.25)
        }
    }
}
