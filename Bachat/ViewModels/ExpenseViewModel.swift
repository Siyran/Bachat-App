import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@MainActor
final class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    private var listenerRegistrations: [Any] = []
    private var isInitialLoad = true
    
    init() { }
    
    func startListening(monthKey: String = DateHelpers.monthKey()) {
        // Cancel old listeners
        for reg in listenerRegistrations {
            if let registration = reg as? FirebaseFirestore.ListenerRegistration {
                registration.remove()
            }
        }
        listenerRegistrations.removeAll()
        isInitialLoad = true
        
        let regs = FirestoreService.shared.listenToExpenses(monthKey: monthKey) { [weak self] newExpenses in
            guard let self = self else { return }
            
            // Check for new shared expenses from the other person
            if !self.isInitialLoad {
                let oldIds = Set(self.expenses.map { $0.id })
                let currentUserEmail = Auth.auth().currentUser?.email ?? ""
                
                for expense in newExpenses {
                    if !oldIds.contains(expense.id) && expense.isShared && expense.paidByEmail != currentUserEmail && expense.paidByEmail != "" {
                        self.triggerNotification(for: expense)
                    }
                }
            }
            
            self.expenses = newExpenses
            self.isInitialLoad = false
        }
        listenerRegistrations = regs
    }
    
    private func triggerNotification(for expense: Expense) {
        let content = UNMutableNotificationContent()
        let roommateName = expense.paidByEmail.components(separatedBy: "@").first ?? "Roommate"
        
        content.title = "New Shared Expense"
        content.body = "\(roommateName) paid \(CurrencyFormatter.format(expense.fullAmount)) for \(expense.category.rawValue). You owe \(CurrencyFormatter.format(expense.fullAmount - expense.amount))."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    deinit {
        for reg in listenerRegistrations {
            if let registration = reg as? FirebaseFirestore.ListenerRegistration {
                registration.remove()
            }
        }
    }

    
    func addExpense(
        amount: Double,
        category: ExpenseCategory,
        note: String,
        date: Date,
        isShared: Bool,
        splitRatio: Double,
        sharedWithEmail: String = ""
    ) {
        let paidByEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let expense = Expense(
            amount: amount,
            category: category,
            note: note,
            date: date,
            isShared: isShared,
            splitRatio: splitRatio,
            paidByEmail: paidByEmail,
            sharedWithEmail: sharedWithEmail
        )
        Task {
            try? await FirestoreService.shared.addExpense(expense)
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        Task {
            try? await FirestoreService.shared.deleteExpense(expense)
        }
    }
}
