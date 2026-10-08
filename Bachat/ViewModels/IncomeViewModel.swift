import SwiftUI
import SwiftData
import FirebaseAuth

@MainActor
final class IncomeViewModel: ObservableObject {
    @Published var expectedSalary: Double
    private var modelContext: ModelContext
    
    init(context: ModelContext, settings: UserSettings) {
        self.modelContext = context
        self.expectedSalary = settings.expectedMonthlySalary
    }
    
    func fetchOrCreateMonth(key: String) -> MonthlyIncome {
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let descriptor = FetchDescriptor<MonthlyIncome>(predicate: #Predicate { $0.monthKey == key && $0.ownerEmail == currentUserEmail })
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let newMonth = MonthlyIncome(monthKey: key, baseSalary: expectedSalary, isProvisional: true)
        newMonth.ownerEmail = currentUserEmail
        modelContext.insert(newMonth)
        try? modelContext.save()
        return newMonth
    }
    
    func fetchAllMonths() -> [MonthlyIncome] {
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let descriptor = FetchDescriptor<MonthlyIncome>(
            predicate: #Predicate { $0.ownerEmail == currentUserEmail },
            sortBy: [SortDescriptor(\.monthKey, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func confirmIncome(month: MonthlyIncome, actualSalary: Double) {
        month.baseSalary = actualSalary
        month.isProvisional = false
        
        // Update user's expected salary for next month
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let descriptor = FetchDescriptor<UserSettings>(predicate: #Predicate { $0.ownerEmail == currentUserEmail })
        if let settings = try? modelContext.fetch(descriptor).first {
            settings.expectedMonthlySalary = actualSalary
            self.expectedSalary = actualSalary
        }
        
        try? modelContext.save()
    }
    
    func addExtraIncome(to month: MonthlyIncome, amount: Double, label: String, type: IncomeType) {
        let entry = IncomeEntry(amount: amount, label: label, type: type)
        month.extras.append(entry)
        try? modelContext.save()
    }
    
    func deleteExtraIncome(_ entry: IncomeEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}
