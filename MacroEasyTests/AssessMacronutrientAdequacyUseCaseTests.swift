//
//  AssessMacronutrientAdequacyUseCaseTests.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import XCTest
@testable import MacroEasy

final class AssessMacronutrientAdequacyUseCaseTests: XCTestCase {
    private var useCase: AssessMacronutrientAdequacyUseCase!

    override func setUp() {
        super.setUp()
        useCase = AssessMacronutrientAdequacyUseCase()
    }

    override func tearDown() {
        useCase = nil
        super.tearDown()
    }

    func test_assessAdequacy_returnsLowStatus_whenIntakeBelow70PercentOfTarget() throws {
        // 65g out of a 100g target is 65% — just under the 70% "low" threshold.
        let progress = MacroProgress(macro: .protein, consumedGrams: 65, targetGrams: 100)

        let assessment = try useCase.execute(macro: .protein, progress: progress, goal: .buildMuscle)

        guard case .low = assessment.status else {
            XCTFail("Expected status .low, got \(assessment.status)")
            return
        }
        XCTAssertFalse(assessment.foodSuggestions.isEmpty)
    }
}
