//
//  GenerateDietaryInsightsUseCaseTests.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import XCTest
@testable import MacroEasy

final class GenerateDietaryInsightUseCaseTests: XCTestCase {
    private var repository: MockNutritionRepository!
    private var useCase: GenerateDietaryInsightUseCase!

    override func setUp() {
        super.setUp()
        repository = MockNutritionRepository()
        useCase = GenerateDietaryInsightUseCase(repository: repository)
    }

    override func tearDown() {
        repository = nil
        useCase = nil
        super.tearDown()
    }

    func test_generateInsight_fails_whenFewerThanThreeDaysLogged() throws {
        let calendar = Calendar.current
        let today = Date()

        // Only 2 distinct days logged — one short of the 3-day minimum.
        try repository.insertMealEntry(sampleEntry(daysAgo: 0, calendar: calendar, referenceDate: today))
        try repository.insertMealEntry(sampleEntry(daysAgo: 1, calendar: calendar, referenceDate: today))

        XCTAssertThrowsError(try useCase.execute(referenceDate: today)) { error in
            guard case GenerateDietaryInsightError.insufficientHistory(let daysLogged, let daysRequired) = error else {
                XCTFail("Expected insufficientHistory, got \(error)")
                return
            }
            XCTAssertEqual(daysLogged, 2)
            XCTAssertEqual(daysRequired, 3)
        }
    }

    private func sampleEntry(daysAgo: Int, calendar: Calendar, referenceDate: Date) -> MealEntry {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate) ?? referenceDate
        return MealEntry(
            id: 0,
            dishName: "Test Meal",
            mealType: .lunch,
            loggedAt: date,
            proteinGrams: 30,
            carbGrams: 30,
            fatGrams: 10,
            calories: 400,
            macrosProvided: true
        )
    }
}
