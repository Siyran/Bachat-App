import SwiftUI
import SwiftData

@MainActor
final class BudgetViewModel: ObservableObject {
    private var modelContext: ModelContext
    
    init(context: ModelContext) {
        self.modelContext = context
    }
    
    func fetchOrCreateConfig() -> BudgetConfig {
        let descriptor = FetchDescriptor<BudgetConfig>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let config = BudgetConfig()
        modelContext.insert(config)
        try? modelContext.save()
        return config
    }
    
    func updateCategoryShare(config: BudgetConfig, category: ExpenseCategory, share: Double) {
        if let existing = config.categoryBudgets.first(where: { $0.category == category }) {
            existing.share = share
        } else {
            let newBudget = CategoryBudget(category: category, share: share)
            config.categoryBudgets.append(newBudget)
        }
        try? modelContext.save()
    }
    
    func checkAlerts(expenses: [Expense], config: BudgetConfig, totalIncome: Double, monthKey: String) {
        let overallLimit = BudgetEngine.monthlySpendingLimit(
            savingsRule: config.savingsRule,
            fixedLimit: config.fixedSpendingLimit,
            comfortableLimit: config.comfortableLimit,
            isComfortableMode: config.isComfortableMode,
            savePercentage: config.savePercentage,
            totalIncome: totalIncome
        )
        
        for catBudget in config.categoryBudgets {
            let catLimit = BudgetEngine.categoryLimit(share: catBudget.share, overallLimit: overallLimit)
            let spent = expenses
                .filter { $0.category == catBudget.category && $0.monthKey == monthKey }
                .reduce(0) { $0 + $1.amount }
            
            let level = BudgetEngine.alertLevel(spent: spent, limit: catLimit)
            if level == .overLimit {
                NotificationManager.shared.scheduleBudgetAlert(
                    title: "Budget Breached! 🚨",
                    body: "You've exceeded your \(catBudget.category.rawValue) budget of \(CurrencyFormatter.format(catLimit))."
                )
            } else if level == .caution {
                NotificationManager.shared.scheduleBudgetAlert(
                    title: "Approaching Limit ⚠️",
                    body: "You've spent \(CurrencyFormatter.format(spent)) of \(CurrencyFormatter.format(catLimit)) for \(catBudget.category.rawValue)."
                )
            }
        }
    }
}
