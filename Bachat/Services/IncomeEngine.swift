import Foundation

/// Pure functions for income calculations.
enum IncomeEngine {

    // MARK: - Totals

    /// Total income = base salary + all extras.
    static func totalIncome(
        baseSalary: Double,
        extras: [(amount: Double, type: IncomeType)]
    ) -> Double {
        baseSalary + extras.reduce(0) { $0 + $1.amount }
    }

    /// Sum of extras that are NOT side income (bonuses, arrears, honoraria).
    static func bonusTotal(
        extras: [(amount: Double, type: IncomeType)]
    ) -> Double {
        extras.filter { $0.type != .sideIncome }.reduce(0) { $0 + $1.amount }
    }

    /// Sum of side-income entries only.
    static func sideIncomeTotal(
        extras: [(amount: Double, type: IncomeType)]
    ) -> Double {
        extras.filter { $0.type == .sideIncome }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Effective Income (provisional vs actual)

    /// Returns the amount to use for calculations and whether it is an estimate.
    /// - When the month's income is confirmed, use the actual figure.
    /// - Otherwise fall back to the expected salary.
    static func effectiveIncome(
        actualIncome: Double?,
        isProvisional: Bool,
        expectedSalary: Double
    ) -> (amount: Double, isEstimated: Bool) {
        if let actual = actualIncome, !isProvisional {
            return (actual, false)
        }
        return (expectedSalary, true)
    }

    // MARK: - Salary-Day Transfer

    /// How much to move to savings on salary day.
    static func salaryDayTransfer(
        totalIncome: Double,
        spendingLimit: Double
    ) -> Double {
        max(totalIncome - spendingLimit, 0)
    }

    // MARK: - Expected Salary Auto-Update

    /// Auto-update expected salary to last month's base salary (if available).
    static func updatedExpectedSalary(
        currentExpected: Double,
        lastMonthBaseSalary: Double?
    ) -> Double {
        lastMonthBaseSalary ?? currentExpected
    }
}
