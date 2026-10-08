import Foundation

enum Constants {
    // MARK: - Income Defaults
    static let defaultExpectedSalary: Double = 40_000
    
    // MARK: - Budget Defaults
    static let defaultSpendingLimit: Double = 12_000
    static let defaultComfortableLimit: Double = 15_000
    static let defaultSavePercentage: Double = 0.65
    static let defaultBonusSavingsPercent: Double = 0.80
    static let defaultSplitRatio: Double = 0.50
    
    // MARK: - Smoke-Free
    static let defaultSmokeDailySavings: Double = 240
    
    // MARK: - Account Defaults
    static let hdfcMinimumBalance: Double = 10_000
    static let defaultHDFCBalance: Double = 6_000
    
    // MARK: - Goal Defaults
    static let defaultGoalAmount: Double = 3_00_000
    static let defaultGoalName: String = "Savings Goal"
    
    // MARK: - Alert Thresholds (fractions)
    static let alertThresholds: [Double] = [0.50, 0.80, 1.00]
    
    // MARK: - Default Category Budget Shares (must sum to 1.0)
    static let defaultCategoryShares: [(ExpenseCategory, Double)] = [
        (.groceries, 0.15),
        (.foodAndEatingOut, 0.20),
        (.transport, 0.10),
        (.household, 0.10),
        (.phoneAndInternet, 0.08),
        (.personal, 0.07),
        (.exploring, 0.15),
        (.sharedWithRoommate, 0.00),   // tracked separately via split
        (.travelHome, 0.10),
        (.misc, 0.05)
    ]
}
