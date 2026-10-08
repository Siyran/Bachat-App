import XCTest
@testable import BachatCore

final class GoalEngineTests: XCTestCase {

    // MARK: - Required Monthly Savings

    func testRequiredFromZero() {
        XCTAssertEqual(GoalEngine.requiredMonthlySavings(targetAmount: 3_00_000, savedSoFar: 0, monthsRemaining: 20), 15_000)
    }

    func testRequiredPartialProgress() {
        XCTAssertEqual(GoalEngine.requiredMonthlySavings(targetAmount: 3_00_000, savedSoFar: 1_00_000, monthsRemaining: 10), 20_000)
    }

    func testRequiredZeroMonths() {
        XCTAssertEqual(GoalEngine.requiredMonthlySavings(targetAmount: 3_00_000, savedSoFar: 2_00_000, monthsRemaining: 0), 1_00_000)
    }

    func testRequiredGoalAlreadyMet() {
        XCTAssertEqual(GoalEngine.requiredMonthlySavings(targetAmount: 3_00_000, savedSoFar: 3_00_000, monthsRemaining: 5), 0)
    }

    func testRequiredGoalExceeded() {
        XCTAssertEqual(GoalEngine.requiredMonthlySavings(targetAmount: 3_00_000, savedSoFar: 3_50_000, monthsRemaining: 5), 0)
    }

    // MARK: - Projected Total

    func testProjectedTotal() {
        let p = GoalEngine.projectedTotalSavings(savedSoFar: 50_000, expectedMonthlySavings: 25_000, monthsRemaining: 10)
        XCTAssertEqual(p, 3_00_000)
    }

    func testProjectedTotalZeroMonths() {
        let p = GoalEngine.projectedTotalSavings(savedSoFar: 50_000, expectedMonthlySavings: 25_000, monthsRemaining: 0)
        XCTAssertEqual(p, 50_000)
    }

    // MARK: - Goal Status

    func testStatusAhead() {
        XCTAssertEqual(
            GoalEngine.goalStatus(savedSoFar: 1_50_000, targetAmount: 3_00_000, monthsElapsed: 8, totalMonths: 20),
            .ahead)
    }

    func testStatusOnTrack() {
        XCTAssertEqual(
            GoalEngine.goalStatus(savedSoFar: 1_20_000, targetAmount: 3_00_000, monthsElapsed: 8, totalMonths: 20),
            .onTrack)
    }

    func testStatusBehind() {
        XCTAssertEqual(
            GoalEngine.goalStatus(savedSoFar: 80_000, targetAmount: 3_00_000, monthsElapsed: 8, totalMonths: 20),
            .behind)
    }

    func testStatusZeroMonths() {
        XCTAssertEqual(
            GoalEngine.goalStatus(savedSoFar: 3_00_000, targetAmount: 3_00_000, monthsElapsed: 20, totalMonths: 0),
            .ahead)
        XCTAssertEqual(
            GoalEngine.goalStatus(savedSoFar: 2_00_000, targetAmount: 3_00_000, monthsElapsed: 20, totalMonths: 0),
            .behind)
    }

    // MARK: - Goal Gap

    func testGapBehind() {
        let gap = GoalEngine.goalGap(savedSoFar: 80_000, targetAmount: 3_00_000, monthsElapsed: 8, totalMonths: 20)
        XCTAssertEqual(gap, 40_000) // expected 1,20,000 − saved 80,000
    }

    func testGapAhead() {
        let gap = GoalEngine.goalGap(savedSoFar: 1_50_000, targetAmount: 3_00_000, monthsElapsed: 8, totalMonths: 20)
        XCTAssertEqual(gap, -30_000) // negative = ahead
    }

    // MARK: - Feasibility

    func testCanMeetGoal() {
        XCTAssertTrue(GoalEngine.canMeetGoal(
            requiredMonthlySavings: 15_000, expectedIncome: 40_000, spendingLimit: 12_000))
    }

    func testCannotMeetGoal() {
        XCTAssertFalse(GoalEngine.canMeetGoal(
            requiredMonthlySavings: 30_000, expectedIncome: 40_000, spendingLimit: 12_000))
    }

    func testShortfall() {
        XCTAssertEqual(
            GoalEngine.monthlyShortfall(requiredMonthlySavings: 30_000, expectedIncome: 40_000, spendingLimit: 12_000),
            2_000)
    }

    func testNoShortfall() {
        XCTAssertEqual(
            GoalEngine.monthlyShortfall(requiredMonthlySavings: 15_000, expectedIncome: 40_000, spendingLimit: 12_000),
            0)
    }

    // MARK: - Smoke-Free

    func testSmokeFreeStreak() {
        let quit = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        XCTAssertEqual(GoalEngine.smokeFreeStreak(quitDate: quit), 30)
    }

    func testSmokeFreeSavings() {
        let quit = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        XCTAssertEqual(GoalEngine.smokeFreeSavings(quitDate: quit, dailySavings: 240), 7_200)
    }

    func testSmokeFreeStreakSameDay() {
        XCTAssertEqual(GoalEngine.smokeFreeStreak(quitDate: Date()), 0)
    }

    // MARK: - What-If

    func testWhatIfCut() {
        XCTAssertEqual(GoalEngine.whatIfCutCategory(monthlyCut: 1_000, monthsRemaining: 20), 20_000)
    }

    func testWhatIfBonus() {
        let months = GoalEngine.whatIfBonus(bonusAmount: 50_000, bonusSavingsPercent: 0.80, requiredMonthlySavings: 20_000)
        XCTAssertEqual(months, 2.0)
    }

    func testWhatIfBonusZeroRequired() {
        XCTAssertEqual(GoalEngine.whatIfBonus(bonusAmount: 50_000, bonusSavingsPercent: 0.80, requiredMonthlySavings: 0), 0)
    }

    // MARK: - Monthly Actuals

    func testSavingsRate() {
        XCTAssertEqual(GoalEngine.savingsRate(totalIncome: 40_000, totalSpent: 12_000), 0.70)
    }

    func testSavingsRateOverspend() {
        XCTAssertEqual(GoalEngine.savingsRate(totalIncome: 40_000, totalSpent: 45_000), 0)
    }

    func testSavingsRateZeroIncome() {
        XCTAssertEqual(GoalEngine.savingsRate(totalIncome: 0, totalSpent: 0), 0)
    }

    func testActualMonthlySavings() {
        XCTAssertEqual(GoalEngine.actualMonthlySavings(totalIncome: 40_000, totalSpent: 12_000), 28_000)
    }

    // MARK: - Variable Past Incomes → Goal Projection

    func testGoalProjectionWithVariableIncomes() {
        let past: [Double] = [28_000, 25_000, 30_000, 20_000, 33_000]
        let totalSaved = past.reduce(0, +) // 1,36,000
        let projected = GoalEngine.projectedTotalSavings(
            savedSoFar: totalSaved, expectedMonthlySavings: 28_000, monthsRemaining: 15)
        XCTAssertEqual(projected, 5_56_000)
        XCTAssertGreaterThanOrEqual(projected, 3_00_000)
    }

    // MARK: - Editing Past Month Recomputes Gap

    func testEditPastMonthRecomputesGap() {
        let origGap = GoalEngine.goalGap(savedSoFar: 1_00_000, targetAmount: 3_00_000, monthsElapsed: 5, totalMonths: 20)
        XCTAssertEqual(origGap, -25_000) // ahead

        let newGap = GoalEngine.goalGap(savedSoFar: 60_000, targetAmount: 3_00_000, monthsElapsed: 5, totalMonths: 20)
        XCTAssertEqual(newGap, 15_000) // behind
    }
}
