import Foundation
import SwiftData

@Model
final class CategoryBudget {
    var id: UUID = UUID()

    /// Stored as ExpenseCategory.rawValue
    var categoryRaw: String = ExpenseCategory.misc.rawValue

    /// Fraction of the overall spending limit (0.0–1.0).
    /// When the overall limit changes, effective limits auto-rescale.
    var share: Double = 0

    /// Inverse side of BudgetConfig.categoryBudgets
    var budgetConfig: BudgetConfig?

    // MARK: - Computed

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .misc }
        set { categoryRaw = newValue.rawValue }
    }

    // MARK: - Init

    init(category: ExpenseCategory, share: Double) {
        self.id = UUID()
        self.categoryRaw = category.rawValue
        self.share = share
    }
}
