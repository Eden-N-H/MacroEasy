//
//  CalculateDailyNutritionProgressUseCaseTests.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import XCTest
@testable import MacroEasy

final class CalculateDailyNutritionProgressUseCaseTests: XCTestCase {
    private var repository: MockNutritionRepository!
    private var useCase: CalculateDailyNutritionProgressUseCase!

    override func setUp() {
        super.setUp()
        repository = MockNutritionRepository()
        useCase = CalculateDailyNutritionProgressUseCase(repository: repository)
    }

    override func tearDown() {
        repository = nil
        useCase = nil
        super.tearDown()
    }

    func test_calculateDailyProgress_fails_whenNoTargetsConfigured() {
        XCTAssertThrowsError(try useCase.execute()) { error in
            guard case CalculateDailyNutritionProgressError.noTargetsConfigured = error else {
                XCTFail("Expected noTargetsConfigured, got \(error)")
                return
            }
        }
    }
}
