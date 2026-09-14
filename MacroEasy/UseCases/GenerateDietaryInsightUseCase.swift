//
//  GenerateDietaryInsightUseCase.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

struct GenerateDietaryInsightUseCase {
    private let repository: NutritionRepository
    private let minimumHistoryDays = 3
    private let windowDays = 7
    private let trendThreshold = 0.10

    init(repository: NutritionRepository) {
        self.repository = repository
    }

    func execute(referenceDate: Date = Date()) throws -> [DietaryInsight] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        guard let windowStart = calendar.date(byAdding: .day, value: -(windowDays - 1), to: today),
              let windowEnd = calendar.date(byAdding: .day, value: 1, to: today) else {
            throw GenerateDietaryInsightError.dataUnavailable
        }

        let entries: [MealEntry]
        do {
            entries = try repository.fetchMealEntries(from: windowStart, to: windowEnd)
        } catch {
            throw GenerateDietaryInsightError.dataUnavailable
        }

        let entriesByDay = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.loggedAt) }
        let loggedDays = entriesByDay.keys.sorted()

        guard loggedDays.count >= minimumHistoryDays else {
            throw GenerateDietaryInsightError.insufficientHistory(
                daysLogged: loggedDays.count,
                daysRequired: minimumHistoryDays
            )
        }

        let midpoint = loggedDays.count / 2
        let earlierDays = Array(loggedDays.prefix(midpoint))
        let laterDays = Array(loggedDays.suffix(loggedDays.count - midpoint))

        var insights: [DietaryInsight] = []

        for macro in Macronutrient.allCases {
            let earlierAverage = averageGrams(for: macro, on: earlierDays, entriesByDay: entriesByDay)
            let laterAverage = averageGrams(for: macro, on: laterDays, entriesByDay: entriesByDay)

            guard earlierAverage > 0 else { continue }

            let percentChange = (laterAverage - earlierAverage) / earlierAverage

            let trend: DietaryInsight.TrendDirection
            if percentChange >= trendThreshold {
                trend = .increasing
            } else if percentChange <= -trendThreshold {
                trend = .decreasing
            } else {
                continue
            }

            let direction = trend == .increasing ? "up" : "down"
            let message = "Your \(macro.displayName.lowercased()) intake is trending \(direction) \(Int(abs(percentChange) * 100))% over the last \(loggedDays.count) days you've logged."

            insights.append(DietaryInsight(
                relatedMacro: macro,
                trendDirection: trend,
                message: message,
                generatedAt: referenceDate
            ))
        }

        if insights.isEmpty {
            insights.append(DietaryInsight(
                relatedMacro: .protein,
                trendDirection: .steady,
                message: "Your intake has been fairly consistent over the last \(loggedDays.count) days you've logged — nice work staying steady.",
                generatedAt: referenceDate
            ))
        }

        return insights
    }

    private func averageGrams(for macro: Macronutrient, on days: [Date], entriesByDay: [Date: [MealEntry]]) -> Double {
        guard !days.isEmpty else { return 0 }
        let total = days.reduce(0.0) { runningTotal, day in
            let dayEntries = entriesByDay[day] ?? []
            let dayTotal = dayEntries.reduce(0.0) { sum, entry in
                switch macro {
                case .protein: return sum + entry.proteinGrams
                case .carbohydrate: return sum + entry.carbGrams
                case .fat: return sum + entry.fatGrams
                }
            }
            return runningTotal + dayTotal
        }
        return total / Double(days.count)
    }
}

enum GenerateDietaryInsightError: LocalizedError {
    case insufficientHistory(daysLogged: Int, daysRequired: Int)
    case dataUnavailable

    var errorDescription: String? {
        switch self {
        case .insufficientHistory(let logged, let required):
            return "Keep logging a little longer — insights need at least \(required) days of history, and you've logged \(logged) so far."
        case .dataUnavailable:
            return "We couldn't load your history right now. Please try again."
        }
    }
}
