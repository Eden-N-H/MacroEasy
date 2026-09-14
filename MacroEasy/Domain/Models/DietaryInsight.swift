//
//  DietaryInsight.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

struct DietaryInsight: Identifiable {
    let id = UUID()
    let relatedMacro: Macronutrient
    let trendDirection: TrendDirection
    let message: String
    let generatedAt: Date

    enum TrendDirection {
        case increasing
        case decreasing
        case steady
    }
}
