import SwiftUI
import SwiftData
import FirebaseAuth

@MainActor
final class DashboardViewModel: ObservableObject {
    private var modelContext: ModelContext
    
    init(context: ModelContext) {
        self.modelContext = context
    }
    
    func fetchOrCreateConfig() -> BudgetConfig {
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let descriptor = FetchDescriptor<BudgetConfig>(predicate: #Predicate { $0.ownerEmail == currentUserEmail })
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let config = BudgetConfig()
        config.ownerEmail = currentUserEmail
        modelContext.insert(config)
        try? modelContext.save()
        return config
    }
    
    func fetchOrCreateIncome(monthKey: String, expectedSalary: Double) -> MonthlyIncome {
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let descriptor = FetchDescriptor<MonthlyIncome>(predicate: #Predicate { $0.monthKey == monthKey && $0.ownerEmail == currentUserEmail })
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let income = MonthlyIncome(monthKey: monthKey, baseSalary: expectedSalary)
        income.ownerEmail = currentUserEmail
        modelContext.insert(income)
        try? modelContext.save()
        return income
    }
    
    func fetchOrCreateAccounts() -> [AccountBalance] {
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let descriptor = FetchDescriptor<AccountBalance>(predicate: #Predicate { $0.ownerEmail == currentUserEmail })
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            return existing
        }
        // Seed defaults
        let hdfc = AccountBalance(name: "HDFC", balance: Constants.defaultHDFCBalance, minimumBalance: Constants.hdfcMinimumBalance)
        hdfc.ownerEmail = currentUserEmail
        let icici = AccountBalance(name: "ICICI", balance: 0, minimumBalance: 0)
        icici.ownerEmail = currentUserEmail
        modelContext.insert(hdfc)
        modelContext.insert(icici)
        try? modelContext.save()
        return [hdfc, icici]
    }
    
    func fetchGoal() -> SavingsGoal? {
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let descriptor = FetchDescriptor<SavingsGoal>(predicate: #Predicate { $0.ownerEmail == currentUserEmail })
        if let existing = try? modelContext.fetch(descriptor).first {
            if existing.name == "Sister's Wedding" {
                existing.name = "Savings Goal"
                try? modelContext.save()
            }
            return existing
        }
        return nil
    }
    
}
