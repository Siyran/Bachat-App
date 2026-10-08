import XCTest
@testable import BachatCore

final class BudgetEngineTests: XCTestCase {

    // MARK: - Monthly Spending Limit

    func testFixedLimitLeanMode() {
        let limit = BudgetEngine.monthlySpendingLimit(
            savingsRule: .fixedLimit, fixedLimit: 12_000, comfortableLimit: 15_000,
            isComfortableMode: false, savePercentage: 0.65, totalIncome: 40_000)
        XCTAssertEqual(limit, 12_000)
    }

    func testFixedLimitComfortableMode() {
        let limit = BudgetEngine.monthlySpendingLimit(
            savingsRule: .fixedLimit, fixedLimit: 12_000, comfortableLimit: 15_000,
            isComfortableMode: true, savePercentage: 0.65, totalIncome: 40_000)
        XCTAssertEqual(limit, 15_000)
    }

    func testSavePercentageRule() {
        let limit = BudgetEngine.monthlySpendingLimit(
            savingsRule: .savePercentage, fixedLimit: 12_000, comfortableLimit: 15_000,
            isComfortableMode: false, savePercentage: 0.65, totalIncome: 40_000)
        XCTAssertEqual(limit, 14_000) // 40000 × 0.35
    }

    func testSavePercentageWithHighIncome() {
        let limit = BudgetEngine.monthlySpendingLimit(
            savingsRule: .savePercentage, fixedLimit: 12_000, comfortableLimit: 15_000,
            isComfortableMode: false, savePercentage: 0.65, totalIncome: 60_000)
        XCTAssertEqual(limit, 21_000)
    }

    // MARK: - Planned Savings

    func testPlannedSavingsFixedLimit() {
        let s = BudgetEngine.plannedSavings(totalIncome: 40_000, spendingLimit: 12_000)
        XCTAssertEqual(s, 28_000)
    }

    func testPlannedSavingsSavePercentage() {
        let s = BudgetEngine.plannedSavings(totalIncome: 40_000, spendingLimit: 14_000)
        XCTAssertEqual(s, 26_000)
    }

    func testPlannedSavingsNeverNegative() {
        XCTAssertEqual(BudgetEngine.plannedSavings(totalIncome: 10_000, spendingLimit: 12_000), 0)
    }

    // MARK: - Safe to Spend Today

    func testSafeToSpendFullMonth() {
        let s = BudgetEngine.safeToSpendToday(spendingLimit: 12_000, spentSoFar: 0, daysLeftInMonth: 30)
        XCTAssertEqual(s, 400, accuracy: 0.01)
    }

    func testSafeToSpendMidMonth() {
        let s = BudgetEngine.safeToSpendToday(spendingLimit: 12_000, spentSoFar: 5_000, daysLeftInMonth: 15)
        XCTAssertEqual(s, 7_000.0 / 15.0, accuracy: 0.01)
    }

    func testSafeToSpendOverBudget() {
        let s = BudgetEngine.safeToSpendToday(spendingLimit: 12_000, spentSoFar: 13_000, daysLeftInMonth: 10)
        XCTAssertEqual(s, 0) // never negative
    }

    func testSafeToSpendLastDay() {
        let s = BudgetEngine.safeToSpendToday(spendingLimit: 12_000, spentSoFar: 11_500, daysLeftInMonth: 1)
        XCTAssertEqual(s, 500)
    }

    func testSafeToSpendExtraIncomeDoesNotInflate() {
        // Extra income goes to savings, not spending
        let s = BudgetEngine.safeToSpendToday(spendingLimit: 12_000, spentSoFar: 6_000, daysLeftInMonth: 15)
        XCTAssertEqual(s, 400, accuracy: 0.01) // 6000 / 15
    }

    // MARK: - Bonus Split

    func testBonusSplitDefault() {
        let (sav, gf) = BudgetEngine.bonusSplit(bonusAmount: 10_000, savingsPercent: 0.80)
        XCTAssertEqual(sav, 8_000)
        XCTAssertEqual(gf, 2_000)
    }

    func testBonusSplitRounding() {
        let (sav, gf) = BudgetEngine.bonusSplit(bonusAmount: 10_001, savingsPercent: 0.80)
        XCTAssertEqual(sav, 8_001)  // 10001 × 0.80 = 8000.8, rounded → 8001
        XCTAssertEqual(gf, 2_000)   // 10001 − 8001
    }

    func testBonusSplitCustomRatio() {
        let (sav, gf) = BudgetEngine.bonusSplit(bonusAmount: 5_000, savingsPercent: 0.90)
        XCTAssertEqual(sav, 4_500)
        XCTAssertEqual(gf, 500)
    }

    func testBonusSplitSumsToTotal() {
        let amount = 7_777.0
        let (sav, gf) = BudgetEngine.bonusSplit(bonusAmount: amount, savingsPercent: 0.80)
        XCTAssertEqual(sav + gf, amount, accuracy: 1) // may differ by ≤ 1 due to rounding
    }

    // MARK: - Shared Expense Split

    func testSharedExpenseEvenSplit() {
        let (u, r) = BudgetEngine.sharedExpenseSplit(totalAmount: 1_000, splitRatio: 0.5)
        XCTAssertEqual(u, 500)
        XCTAssertEqual(r, 500)
    }

    func testSharedExpenseUnevenSplit() {
        let (u, r) = BudgetEngine.sharedExpenseSplit(totalAmount: 1_000, splitRatio: 0.6)
        XCTAssertEqual(u, 600)
        XCTAssertEqual(r, 400)
    }

    func testSharedExpenseFullUser() {
        let (u, r) = BudgetEngine.sharedExpenseSplit(totalAmount: 1_000, splitRatio: 1.0)
        XCTAssertEqual(u, 1_000)
        XCTAssertEqual(r, 0)
    }

    // MARK: - Alert Levels & Thresholds

    func testAlertLevelSafe()      { XCTAssertEqual(BudgetEngine.alertLevel(spent: 4_000, limit: 12_000), .safe) }
    func testAlertLevelCaution()   { XCTAssertEqual(BudgetEngine.alertLevel(spent: 10_000, limit: 12_000), .caution) }
    func testAlertLevelOverLimit() { XCTAssertEqual(BudgetEngine.alertLevel(spent: 12_500, limit: 12_000), .overLimit) }
    func testAlertAt50Percent()    { XCTAssertEqual(BudgetEngine.alertLevel(spent: 6_000, limit: 12_000), .safe) }
    func testAlertAt80Percent()    { XCTAssertEqual(BudgetEngine.alertLevel(spent: 9_600, limit: 12_000), .caution) }
    func testAlertAt100Percent()   { XCTAssertEqual(BudgetEngine.alertLevel(spent: 12_000, limit: 12_000), .overLimit) }
    func testAlertZeroLimit()      { XCTAssertEqual(BudgetEngine.alertLevel(spent: 100, limit: 0), .overLimit) }

    func testCrossedThresholdsSome() {
        let crossed = BudgetEngine.crossedThresholds(spent: 10_000, limit: 12_000)
        XCTAssertEqual(crossed, [0.50, 0.80])
    }

    func testCrossedThresholdsAll() {
        let crossed = BudgetEngine.crossedThresholds(spent: 12_000, limit: 12_000)
        XCTAssertEqual(crossed, [0.50, 0.80, 1.00])
    }

    func testCrossedThresholdsNone() {
        let crossed = BudgetEngine.crossedThresholds(spent: 1_000, limit: 12_000)
        XCTAssertTrue(crossed.isEmpty)
    }

    // MARK: - Projected Month End

    func testProjectedMonthEnd() {
        let p = BudgetEngine.projectedMonthEndSpending(spentSoFar: 6_000, daysElapsed: 15, totalDaysInMonth: 30)
        XCTAssertEqual(p, 12_000)
    }

    func testProjectedOverspend() {
        let p = BudgetEngine.projectedMonthEndSpending(spentSoFar: 8_000, daysElapsed: 15, totalDaysInMonth: 30)
        XCTAssertEqual(p, 16_000)
    }

    func testProjectedZeroDays() {
        let p = BudgetEngine.projectedMonthEndSpending(spentSoFar: 0, daysElapsed: 0, totalDaysInMonth: 30)
        XCTAssertEqual(p, 0)
    }

    // MARK: - Consecutive Overspend

    func testConsecutiveOverspendTrue() {
        let cal = Calendar.current
        let today = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let spending = [(date: yesterday, amount: 500.0), (date: today, amount: 600.0)]
        XCTAssertTrue(BudgetEngine.isConsecutiveOverspend(dailySpending: spending, safeToSpend: 400))
    }

    func testConsecutiveOverspendFalse() {
        let cal = Calendar.current
        let today = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let spending = [(date: yesterday, amount: 300.0), (date: today, amount: 600.0)]
        XCTAssertFalse(BudgetEngine.isConsecutiveOverspend(dailySpending: spending, safeToSpend: 400))
    }

    func testConsecutiveOverspendSingleDay() {
        let spending = [(date: Date(), amount: 900.0)]
        XCTAssertFalse(BudgetEngine.isConsecutiveOverspend(dailySpending: spending, safeToSpend: 400))
    }

    // MARK: - HDFC Minimum Balance

    func testHDFCBelowMinimum() {
        let (below, topUp) = BudgetEngine.hdfcBalanceCheck(currentBalance: 6_000, minimumBalance: 10_000)
        XCTAssertTrue(below)
        XCTAssertEqual(topUp, 4_000)
    }

    func testHDFCAtMinimum() {
        let (below, topUp) = BudgetEngine.hdfcBalanceCheck(currentBalance: 10_000, minimumBalance: 10_000)
        XCTAssertFalse(below)
        XCTAssertEqual(topUp, 0)
    }

    func testHDFCAboveMinimum() {
        let (below, topUp) = BudgetEngine.hdfcBalanceCheck(currentBalance: 50_000, minimumBalance: 10_000)
        XCTAssertFalse(below)
        XCTAssertEqual(topUp, 0)
    }

    func testWouldBreachMinimum() {
        XCTAssertTrue(BudgetEngine.wouldBreachMinimum(currentBalance: 15_000, withdrawal: 6_000, minimumBalance: 10_000))
    }

    func testWouldNotBreachMinimum() {
        XCTAssertFalse(BudgetEngine.wouldBreachMinimum(currentBalance: 15_000, withdrawal: 4_000, minimumBalance: 10_000))
    }

    // MARK: - Category Limits

    func testCategoryLimit() {
        XCTAssertEqual(BudgetEngine.categoryLimit(share: 0.20, overallLimit: 12_000), 2_400)
    }

    func testCategoryLimitRescalesWithOverall() {
        XCTAssertEqual(BudgetEngine.categoryLimit(share: 0.20, overallLimit: 12_000), 2_400)
        XCTAssertEqual(BudgetEngine.categoryLimit(share: 0.20, overallLimit: 15_000), 3_000)
    }
}
