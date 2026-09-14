//
//  AssessMacronutrientAdequacyUseCase.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation


struct MacronutrientAdequacyAssessment {
    let macro: Macronutrient
    let status: AdequacyStatus
    let explanation: String
    let foodSuggestions: [String]
}

struct AssessMacronutrientAdequacyUseCase {
    private let educationContent: [Macronutrient: MacronutrientEducationContent]
    private let lowThreshold = 0.70
    private let highThreshold = 1.30

    init(educationContent: [Macronutrient: MacronutrientEducationContent] = MacronutrientEducationContent.all) {
        self.educationContent = educationContent
    }

    func execute(
        macro: Macronutrient,
        progress: MacroProgress,
        goal: NutritionGoal
    ) throws -> MacronutrientAdequacyAssessment {
        guard progress.targetGrams > 0 else {
            throw AssessMacronutrientAdequacyError.targetNotSet
        }

        guard let content = educationContent[macro] else {
            throw AssessMacronutrientAdequacyError.educationContentUnavailable
        }

        let status = adequacyStatus(for: progress.progressFraction)
        let goalGuidance = content.goalSpecificGuidance[goal] ?? content.whyYouNeedIt
        let explanation = "\(statusHeadline(status, macro: macro)) \(goalGuidance)"

        return MacronutrientAdequacyAssessment(
            macro: macro,
            status: status,
            explanation: explanation,
            foodSuggestions: status == .low ? content.foodSuggestions : []
        )
    }

    private func adequacyStatus(for fraction: Double) -> AdequacyStatus {
        switch fraction {
        case ..<0.70: return .low
        case 0.70...1.30: return .onTrack
        default: return .high
        }
    }

    private func statusHeadline(_ status: AdequacyStatus, macro: Macronutrient) -> String {
        let name = macro.displayName.lowercased()
        switch status {
        case .low: return "You're below your \(name) target today."
        case .onTrack: return "You're on track with your \(name) today."
        case .high: return "You're above your \(name) target today."
        }
    }
}

enum AssessMacronutrientAdequacyError: LocalizedError {
    case targetNotSet
    case educationContentUnavailable

    var errorDescription: String? {
        switch self {
        case .targetNotSet:
            return "Set a target for this macronutrient before we can tell you how you're tracking."
        case .educationContentUnavailable:
            return "We don't have guidance available for this macronutrient yet."
        }
    }
}
