//
//  SetNutritionTargetsUseCaseTests.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import XCTest
@testable import MacroEasy

final class SetNutritionTargetsUseCaseTests: XCTestCase {
    private var repository: MockNutritionRepository!
    private var useCase: SetNutritionTargetsUseCase!

    override func setUp() {
        super.setUp()
        repository = MockNutritionRepository()
        useCase = SetNutritionTargetsUseCase(repository: repository)
    }

    override func tearDown() {
        repository = nil
        useCase = nil
        super.tearDown()
    }

    func test_setNutritionTargets_succeeds_withGoalBasedMacros() throws {
        let suggestion = SetNutritionTargetsUseCase.suggestedMacros(for: .buildMuscle, calories: 2500)

        let targets = try useCase.execute(
            goal: .buildMuscle,
            calories: 2500,
            proteinGrams: suggestion.proteinGrams,
            carbGrams: suggestion.carbGrams,
            fatGrams: suggestion.fatGrams
        )

        XCTAssertEqual(targets.goal, .buildMuscle)
        XCTAssertEqual(try repository.fetchNutritionTargets()?.calories, 2500)
    }

    func test_setNutritionTargets_fails_whenCalorieTargetIsZero() {
        XCTAssertThrowsError(
            try useCase.execute(goal: .maintain, calories: 0, proteinGrams: 100, carbGrams: 100, fatGrams: 50)
        ) { error in
            guard case SetNutritionTargetsError.invalidCalorieTarget = error else {
                XCTFail("Expected invalidCalorieTarget, got \(error)")
                return
            }
        }
    }
}
