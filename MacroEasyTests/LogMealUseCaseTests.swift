//
//  LogMealUseCaseTests.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import XCTest
@testable import MacroEasy

final class LogMealUseCaseTests: XCTestCase {
    private var repository: MockNutritionRepository!
    private var useCase: LogMealUseCase!

    override func setUp() {
        super.setUp()
        repository = MockNutritionRepository()
        useCase = LogMealUseCase(repository: repository)
    }

    override func tearDown() {
        repository = nil
        useCase = nil
        super.tearDown()
    }

    func test_logMeal_succeeds_withValidCaloriesAndMacros() throws {
        let entry = try useCase.execute(
            dishName: "Grilled Chicken",
            mealType: .lunch,
            calories: 348,
            proteinGrams: 40,
            carbGrams: 20,
            fatGrams: 12
        )

        XCTAssertEqual(entry.dishName, "Grilled Chicken")
        XCTAssertTrue(entry.macrosProvided)
        XCTAssertEqual(try repository.fetchMealEntries(on: Date()).count, 1)
    }

    func test_logMeal_fails_whenDishNameIsEmpty() {
        XCTAssertThrowsError(
            try useCase.execute(dishName: "   ", mealType: .breakfast, calories: 300)
        ) { error in
            guard case LogMealError.missingDishName = error else {
                XCTFail("Expected missingDishName, got \(error)")
                return
            }
        }
    }

    func test_logMeal_fails_whenCaloriesExceedMacroToleranceBoundary() {
        // 50g protein + 50g carb + 10g fat implies 490 kcal.
        // 10% tolerance allows up to 539; 540 sits just outside that boundary.
        XCTAssertThrowsError(
            try useCase.execute(
                dishName: "Boundary Test Meal",
                mealType: .dinner,
                calories: 540,
                proteinGrams: 50,
                carbGrams: 50,
                fatGrams: 10
            )
        ) { error in
            guard case LogMealError.calorieMismatch = error else {
                XCTFail("Expected calorieMismatch, got \(error)")
                return
            }
        }
    }
}
