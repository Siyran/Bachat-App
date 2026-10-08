import XCTest
@testable import BachatCore

final class IncomeEngineTests: XCTestCase {

    // MARK: - Total Income

    func testBaseSalaryOnly() {
        let t = IncomeEngine.totalIncome(baseSalary: 40_000, extras: [])
        XCTAssertEqual(t, 40_000)
    }

    func testWithOneBonus() {
        let extras: [(amount: Double, type: IncomeType)] = [
            (5_000, .bonus)
        ]
        XCTAssertEqual(IncomeEngine.totalIncome(baseSalary: 40_000, extras: extras), 45_000)
    }

    func testWithMultipleExtras() {
        let extras: [(amount: Double, type: IncomeType)] = [
            (5_000, .bonus),
            (3_000, .arrears),
            (2_000, .honorarium),
            (8_000, .sideIncome),
        ]
        XCTAssertEqual(IncomeEngine.totalIncome(baseSalary: 40_000, extras: extras), 58_000)
    }

    // MARK: - Bonus vs Side Income

    func testBonusTotal() {
        let extras: [(amount: Double, type: IncomeType)] = [
            (5_000, .bonus),
            (3_000, .arrears),
            (8_000, .sideIncome),
        ]
        XCTAssertEqual(IncomeEngine.bonusTotal(extras: extras), 8_000) // bonus + arrears
    }

    func testSideIncomeTotal() {
        let extras: [(amount: Double, type: IncomeType)] = [
            (5_000, .bonus),
            (3_000, .sideIncome),
            (2_000, .sideIncome),
        ]
        XCTAssertEqual(IncomeEngine.sideIncomeTotal(extras: extras), 5_000)
    }

    func testBonusTotalEmpty() {
        XCTAssertEqual(IncomeEngine.bonusTotal(extras: []), 0)
    }

    // MARK: - Effective Income (provisional ↔ actual)

    func testEffectiveIncomeActual() {
        let (amt, est) = IncomeEngine.effectiveIncome(
            actualIncome: 42_000, isProvisional: false, expectedSalary: 40_000)
        XCTAssertEqual(amt, 42_000)
        XCTAssertFalse(est)
    }

    func testEffectiveIncomeProvisional() {
        let (amt, est) = IncomeEngine.effectiveIncome(
            actualIncome: 42_000, isProvisional: true, expectedSalary: 40_000)
        XCTAssertEqual(amt, 40_000)
        XCTAssertTrue(est)
    }

    func testEffectiveIncomeNil() {
        let (amt, est) = IncomeEngine.effectiveIncome(
            actualIncome: nil, isProvisional: true, expectedSalary: 40_000)
        XCTAssertEqual(amt, 40_000)
        XCTAssertTrue(est)
    }

    func testSwitchFromEstimatedToActual() {
        // Before entering income
        let (e1, est1) = IncomeEngine.effectiveIncome(
            actualIncome: nil, isProvisional: true, expectedSalary: 40_000)
        XCTAssertTrue(est1)
        XCTAssertEqual(e1, 40_000)

        // After entering income
        let (e2, est2) = IncomeEngine.effectiveIncome(
            actualIncome: 45_000, isProvisional: false, expectedSalary: 40_000)
        XCTAssertFalse(est2)
        XCTAssertEqual(e2, 45_000)
    }

    // MARK: - Salary-Day Transfer

    func testSalaryDayTransfer() {
        XCTAssertEqual(IncomeEngine.salaryDayTransfer(totalIncome: 40_000, spendingLimit: 12_000), 28_000)
    }

    func testSalaryDayTransferLowIncome() {
        XCTAssertEqual(IncomeEngine.salaryDayTransfer(totalIncome: 10_000, spendingLimit: 12_000), 0)
    }

    // MARK: - Expected Salary Auto-Update

    func testExpectedSalaryUpdates() {
        XCTAssertEqual(IncomeEngine.updatedExpectedSalary(currentExpected: 40_000, lastMonthBaseSalary: 42_000), 42_000)
    }

    func testExpectedSalaryKeepsCurrent() {
        XCTAssertEqual(IncomeEngine.updatedExpectedSalary(currentExpected: 40_000, lastMonthBaseSalary: nil), 40_000)
    }

    // MARK: - Planned Savings Under Both Rules

    func testPlannedSavingsFixedLimit() {
        let limit = BudgetEngine.monthlySpendingLimit(
            savingsRule: .fixedLimit, fixedLimit: 12_000, comfortableLimit: 15_000,
            isComfortableMode: false, savePercentage: 0.65, totalIncome: 40_000)
        XCTAssertEqual(BudgetEngine.plannedSavings(totalIncome: 40_000, spendingLimit: limit), 28_000)
    }

    func testPlannedSavingsSavePercentage() {
        let limit = BudgetEngine.monthlySpendingLimit(
            savingsRule: .savePercentage, fixedLimit: 12_000, comfortableLimit: 15_000,
            isComfortableMode: false, savePercentage: 0.65, totalIncome: 40_000)
        XCTAssertEqual(BudgetEngine.plannedSavings(totalIncome: 40_000, spendingLimit: limit), 26_000)
    }

    // MARK: - Editing Income Recomputes

    func testEditingIncomeRecomputesSavings() {
        let limit = 12_000.0
        XCTAssertEqual(BudgetEngine.plannedSavings(totalIncome: 40_000, spendingLimit: limit), 28_000)

        // User adds a bonus
        let newIncome = IncomeEngine.totalIncome(baseSalary: 40_000, extras: [(5_000, .bonus)])
        XCTAssertEqual(BudgetEngine.plannedSavings(totalIncome: newIncome, spendingLimit: limit), 33_000)
    }
}
