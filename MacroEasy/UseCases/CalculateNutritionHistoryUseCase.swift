//
//  CalculateNutritionHistoryUseCase.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//
//  CalculateNutritionHistoryUseCase.swift

import Foundation

enum HistoryTimeRange: String, CaseIterable, Identifiable {
    case week
    case month
    case year

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

struct NutritionHistoryPoint: Identifiable {
    let id = UUID()
    let periodStart: Date
    let calories: Double
    let proteinGrams: Double
    let carbGrams: Double
    let fatGrams: Double
    let hasEntries: Bool

    func value(for metric: HistoryMetric) -> Double {
        switch metric {
        case .calories: return calories
        case .macro(.protein): return proteinGrams
        case .macro(.carbohydrate): return carbGrams
        case .macro(.fat): return fatGrams
        }
    }
}

/// Aggregates logged meals into a series of data points suitable for a bar
/// chart, over a week, month, or year.
///
/// Business rule: week and month views bucket by day; the year view buckets
/// by month, since 365 individual daily bars would be unreadable.
struct CalculateNutritionHistoryUseCase {
    private let repository: NutritionRepository
    private let calendar = Calendar.current

    init(repository: NutritionRepository) {
        self.repository = repository
    }

    func execute(range: HistoryTimeRange, referenceDate: Date = Date()) throws -> [NutritionHistoryPoint] {
        switch range {
        case .week:
            return try dailyPoints(daysBack: 6, referenceDate: referenceDate)
        case .month:
            return try dailyPoints(daysBack: 29, referenceDate: referenceDate)
        case .year:
            return try monthlyPoints(referenceDate: referenceDate)
        }
    }

    private func dailyPoints(daysBack: Int, referenceDate: Date) throws -> [NutritionHistoryPoint] {
        let today = calendar.startOfDay(for: referenceDate)
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: today),
              let endDate = calendar.date(byAdding: .day, value: 1, to: today) else {
            throw CalculateNutritionHistoryError.dataUnavailable
        }

        let entries: [MealEntry]
        do {
            entries = try repository.fetchMealEntries(from: startDate, to: endDate)
        } catch {
            throw CalculateNutritionHistoryError.dataUnavailable
        }

        let entriesByDay = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.loggedAt) }

        var points: [NutritionHistoryPoint] = []
        var currentDay = startDate
        while currentDay <= today {
            let dayEntries = entriesByDay[currentDay] ?? []
            points.append(
                NutritionHistoryPoint(
                    periodStart: currentDay,
                    calories: dayEntries.reduce(0) { $0 + $1.calories },
                    proteinGrams: dayEntries.reduce(0) { $0 + $1.proteinGrams },
                    carbGrams: dayEntries.reduce(0) { $0 + $1.carbGrams },
                    fatGrams: dayEntries.reduce(0) { $0 + $1.fatGrams },
                    hasEntries: !dayEntries.isEmpty
                )
            )
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }
        return points
    }

    private func monthlyPoints(referenceDate: Date) throws -> [NutritionHistoryPoint] {
        guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)),
              let startDate = calendar.date(byAdding: .month, value: -11, to: startOfCurrentMonth),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startOfCurrentMonth) else {
            throw CalculateNutritionHistoryError.dataUnavailable
        }

        let entries: [MealEntry]
        do {
            entries = try repository.fetchMealEntries(from: startDate, to: endDate)
        } catch {
            throw CalculateNutritionHistoryError.dataUnavailable
        }

        let entriesByMonth = Dictionary(grouping: entries) { entry -> Date in
            let components = calendar.dateComponents([.year, .month], from: entry.loggedAt)
            return calendar.date(from: components) ?? entry.loggedAt
        }

        var points: [NutritionHistoryPoint] = []
        var currentMonth = startDate
        while currentMonth <= startOfCurrentMonth {
            let monthEntries = entriesByMonth[currentMonth] ?? []
            points.append(
                NutritionHistoryPoint(
                    periodStart: currentMonth,
                    calories: monthEntries.reduce(0) { $0 + $1.calories },
                    proteinGrams: monthEntries.reduce(0) { $0 + $1.proteinGrams },
                    carbGrams: monthEntries.reduce(0) { $0 + $1.carbGrams },
                    fatGrams: monthEntries.reduce(0) { $0 + $1.fatGrams },
                    hasEntries: !monthEntries.isEmpty
                )
            )
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { break }
            currentMonth = nextMonth
        }
        return points
    }
}

enum CalculateNutritionHistoryError: LocalizedError {
    case dataUnavailable

    var errorDescription: String? {
        switch self {
        case .dataUnavailable:
            return "We couldn't load your history right now. Please try again."
        }
    }
}
