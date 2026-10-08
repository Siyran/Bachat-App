import Foundation

/// Pure functions for budget calculations.
/// Takes simple values (not SwiftData models) so everything is testable without a model container.
enum BudgetEngine {

    // MARK: - Spending Limit

    /// Monthly spending limit based on the active savings rule.
    static func monthlySpendingLimit(
        savingsRule: SavingsRule,
        fixedLimit: Double,
        comfortableLimit: Double,
        isComfortableMode: Bool,
        savePercentage: Double,
        totalIncome: Double
    ) -> Double {
        switch savingsRule {
        case .fixedLimit:
            return isComfortableMode ? comfortableLimit : fixedLimit
        case .savePercentage:
            return totalIncome * (1 - savePercentage)
        }
    }

    // MARK: - Savings

    /// Planned savings = income − spending limit (never negative).
    static func plannedSavings(totalIncome: Double, spendingLimit: Double) -> Double {
        max(totalIncome - spendingLimit, 0)
    }

    // MARK: - Safe to Spend

    /// Remaining budget spread evenly over the days left (including today).
    /// Extra income never inflates this — it uses the *limit*, not income.
    static func safeToSpendToday(
        spendingLimit: Double,
        spentSoFar: Double,
        daysLeftInMonth: Int
    ) -> Double {
        let remaining = spendingLimit - spentSoFar
        let days = max(daysLeftInMonth, 1)
        return max(remaining / Double(days), 0)
    }

    // MARK: - Category Budget

    /// Effective limit for a category = its share × the overall limit.
    static func categoryLimit(share: Double, overallLimit: Double) -> Double {
        share * overallLimit
    }

    // MARK: - Alert Levels

    /// Traffic-light status for any amount vs. its limit.
    static func alertLevel(spent: Double, limit: Double) -> AlertLevel {
        guard limit > 0 else { return .overLimit }
        let ratio = spent / limit
        if ratio >= 1.0 { return .overLimit }
        if ratio >= 0.80 { return .caution }
        return .safe
    }

    /// Returns the subset of `thresholds` that the ratio has crossed.
    static func crossedThresholds(
        spent: Double,
        limit: Double,
        thresholds: [Double] = Constants.alertThresholds
    ) -> [Double] {
        guard limit > 0 else { return thresholds }
        let ratio = spent / limit
        return thresholds.filter { ratio >= $0 }
    }

    // MARK: - Bonus Split

    /// Split a bonus into a savings portion and guilt-free spending.
    /// The savings portion is rounded to the nearest rupee.
    static func bonusSplit(
        bonusAmount: Double,
        savingsPercent: Double
    ) -> (savings: Double, guiltFree: Double) {
        let savings = (bonusAmount * savingsPercent).rounded()
        let guiltFree = bonusAmount - savings
        return (savings, guiltFree)
    }

    // MARK: - Projections

    /// Linear projection of month-end spending based on current pace.
    static func projectedMonthEndSpending(
        spentSoFar: Double,
        daysElapsed: Int,
        totalDaysInMonth: Int
    ) -> Double {
        guard daysElapsed > 0 else { return 0 }
        let dailyRate = spentSoFar / Double(daysElapsed)
        return dailyRate * Double(totalDaysInMonth)
    }

    /// True when the user has exceeded safe-to-spend on two consecutive days.
    static func isConsecutiveOverspend(
        dailySpending: [(date: Date, amount: Double)],
        safeToSpend: Double
    ) -> Bool {
        let sorted = dailySpending.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return false }
        for i in 1..<sorted.count {
            if sorted[i].amount > safeToSpend && sorted[i - 1].amount > safeToSpend {
                return true
            }
        }
        return false
    }

    // MARK: - Shared Expenses

    /// Split a total bill between user and roommate.
    static func sharedExpenseSplit(
        totalAmount: Double,
        splitRatio: Double
    ) -> (userShare: Double, roommateShare: Double) {
        let userShare = totalAmount * splitRatio
        let roommateShare = totalAmount - userShare
        return (userShare, roommateShare)
    }

    // MARK: - HDFC Minimum Balance

    /// Check whether the balance is below the floor and how much to top up.
    static func hdfcBalanceCheck(
        currentBalance: Double,
        minimumBalance: Double
    ) -> (isBelowMinimum: Bool, topUpNeeded: Double) {
        let deficit = minimumBalance - currentBalance
        return (deficit > 0, max(deficit, 0))
    }

    /// Would a withdrawal push the balance below the minimum?
    static func wouldBreachMinimum(
        currentBalance: Double,
        withdrawal: Double,
        minimumBalance: Double
    ) -> Bool {
        (currentBalance - withdrawal) < minimumBalance
    }
}
