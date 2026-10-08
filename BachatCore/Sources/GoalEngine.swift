import Foundation

/// Pure functions for savings-goal projections and smoke-free tracking.
enum GoalEngine {

    // MARK: - Months Remaining

    /// Full calendar months from `date` to `targetDate`.
    static func monthsRemaining(from date: Date = Date(), to targetDate: Date) -> Int {
        DateHelpers.monthsBetween(from: date, to: targetDate)
    }

    // MARK: - Required Monthly Savings

    /// How much must be saved each remaining month to hit the target.
    static func requiredMonthlySavings(
        targetAmount: Double,
        savedSoFar: Double,
        monthsRemaining: Int
    ) -> Double {
        let gap = targetAmount - savedSoFar
        guard gap > 0 else { return 0 }
        guard monthsRemaining > 0 else { return gap }
        return gap / Double(monthsRemaining)
    }

    // MARK: - Projected Total

    /// Project how much will be saved by the deadline.
    static func projectedTotalSavings(
        savedSoFar: Double,
        expectedMonthlySavings: Double,
        monthsRemaining: Int
    ) -> Double {
        savedSoFar + expectedMonthlySavings * Double(max(monthsRemaining, 0))
    }

    // MARK: - Goal Status

    /// Compare actual savings to where we "should" be on a linear schedule.
    static func goalStatus(
        savedSoFar: Double,
        targetAmount: Double,
        monthsElapsed: Int,
        totalMonths: Int
    ) -> GoalStatus {
        guard totalMonths > 0 else {
            return savedSoFar >= targetAmount ? .ahead : .behind
        }
        let expectedByNow = targetAmount * (Double(monthsElapsed) / Double(totalMonths))
        let ratio = savedSoFar / max(expectedByNow, 1)

        if ratio >= 1.05 { return .ahead }
        if ratio >= 0.95 { return .onTrack }
        return .behind
    }

    /// Gap between where we should be and where we are.
    /// Positive = behind, negative = ahead.
    static func goalGap(
        savedSoFar: Double,
        targetAmount: Double,
        monthsElapsed: Int,
        totalMonths: Int
    ) -> Double {
        guard totalMonths > 0 else { return targetAmount - savedSoFar }
        let expectedByNow = targetAmount * (Double(monthsElapsed) / Double(totalMonths))
        return expectedByNow - savedSoFar
    }

    // MARK: - Feasibility

    /// Can the goal be met with the given income and spending limit?
    static func canMeetGoal(
        requiredMonthlySavings: Double,
        expectedIncome: Double,
        spendingLimit: Double
    ) -> Bool {
        (expectedIncome - spendingLimit) >= requiredMonthlySavings
    }

    /// Monthly shortfall if the goal can't be met (0 if it can).
    static func monthlyShortfall(
        requiredMonthlySavings: Double,
        expectedIncome: Double,
        spendingLimit: Double
    ) -> Double {
        let possible = expectedIncome - spendingLimit
        return max(requiredMonthlySavings - possible, 0)
    }

    // MARK: - Smoke-Free

    /// Days since the quit date.
    static func smokeFreeStreak(quitDate: Date, asOf: Date = Date()) -> Int {
        DateHelpers.daysBetween(from: quitDate, to: asOf)
    }

    /// Total ₹ saved by not smoking.
    static func smokeFreeSavings(
        quitDate: Date,
        dailySavings: Double,
        asOf: Date = Date()
    ) -> Double {
        Double(smokeFreeStreak(quitDate: quitDate, asOf: asOf)) * dailySavings
    }

    // MARK: - What-If Projections

    /// Extra savings if a category is cut by `monthlyCut` for the remaining months.
    static func whatIfCutCategory(
        monthlyCut: Double,
        monthsRemaining: Int
    ) -> Double {
        monthlyCut * Double(max(monthsRemaining, 0))
    }

    /// How many months closer a one-time bonus brings the goal.
    static func whatIfBonus(
        bonusAmount: Double,
        bonusSavingsPercent: Double,
        requiredMonthlySavings: Double
    ) -> Double {
        guard requiredMonthlySavings > 0 else { return 0 }
        let bonusSavings = bonusAmount * bonusSavingsPercent
        return bonusSavings / requiredMonthlySavings
    }

    // MARK: - Monthly Actuals

    /// Actual savings for one month.
    static func actualMonthlySavings(
        totalIncome: Double,
        totalSpent: Double
    ) -> Double {
        max(totalIncome - totalSpent, 0)
    }

    /// Savings rate as a fraction (0–1).
    static func savingsRate(
        totalIncome: Double,
        totalSpent: Double
    ) -> Double {
        guard totalIncome > 0 else { return 0 }
        return max(totalIncome - totalSpent, 0) / totalIncome
    }
}
