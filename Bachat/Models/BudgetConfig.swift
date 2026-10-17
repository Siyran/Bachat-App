import Foundation
import SwiftData

/// Persistent configuration model defining active savings rules, spending limits, and category allocations.
@Model
final class BudgetConfig {
    /// Unique identifier for the budget configuration profile.
    var id: UUID = UUID()
    
    /// User identifier owning this budget configuration.
    var ownerEmail: String = ""

    /// Which savings rule is active
    var savingsRuleRaw: String = SavingsRule.fixedLimit.rawValue

    /// Lean-mode spending limit (used when savingsRule == .fixedLimit && !isComfortableMode)
    var fixedSpendingLimit: Double = Constants.defaultSpendingLimit

    /// Percentage of income to save (used when savingsRule == .savePercentage)
    var savePercentage: Double = Constants.defaultSavePercentage

    /// Comfortable-mode limit
    var comfortableLimit: Double = Constants.defaultComfortableLimit

    /// Toggle between lean (₹12K) and comfortable (₹15K)
    var isComfortableMode: Bool = false

    /// Default share of a bonus that goes to savings
    var bonusSavingsPercent: Double = Constants.defaultBonusSavingsPercent

    /// Per-category allocations (shares must sum ≤ 1.0)
    @Relationship(deleteRule: .cascade, inverse: \CategoryBudget.budgetConfig)
    var categoryBudgets: [CategoryBudget] = []

    // MARK: - Computed

    var savingsRule: SavingsRule {
        get { SavingsRule(rawValue: savingsRuleRaw) ?? .fixedLimit }
        set { savingsRuleRaw = newValue.rawValue }
    }

    // MARK: - Init (uses defaults from Constants)

    init() {
        self.id = UUID()
        self.savingsRuleRaw = SavingsRule.fixedLimit.rawValue
        self.fixedSpendingLimit = Constants.defaultSpendingLimit
        self.savePercentage = Constants.defaultSavePercentage
        self.comfortableLimit = Constants.defaultComfortableLimit
        self.isComfortableMode = false
        self.bonusSavingsPercent = Constants.defaultBonusSavingsPercent
        self.categoryBudgets = []
    }
}
