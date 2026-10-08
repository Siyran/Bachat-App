import Foundation
import FirebaseFirestore
import FirebaseAuth

enum FirestoreError: Error {
    case notAuthenticated
    case decodingError
    case unknown
}

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Helper to get the current user ID
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Expenses
    
    func addExpense(_ expense: Expense) async throws {
        guard let uid = currentUserId else { throw FirestoreError.notAuthenticated }
        if expense.isShared {
            let ref = db.collection("shared_expenses").document(expense.id)
            try ref.setData(from: expense)
        } else {
            let ref = db.collection("users").document(uid).collection("expenses").document(expense.id)
            try ref.setData(from: expense)
        }
    }
    
    func deleteExpense(_ expense: Expense) async throws {
        guard let uid = currentUserId else { throw FirestoreError.notAuthenticated }
        if expense.isShared {
            try await db.collection("shared_expenses").document(expense.id).delete()
        } else {
            try await db.collection("users").document(uid).collection("expenses").document(expense.id).delete()
        }
    }
    
    // Listen to real-time expense updates for a specific month
    func listenToExpenses(monthKey: String, completion: @escaping ([Expense]) -> Void) -> [ListenerRegistration] {
        guard let uid = currentUserId, let rawEmail = Auth.auth().currentUser?.email else { return [] }
        let email = rawEmail.lowercased()
        
        var personalExpenses: [Expense] = []
        var sharedExpenses: [Expense] = []
        
        func emitCombined() {
            let combined = (personalExpenses + sharedExpenses).sorted { $0.date > $1.date }
            completion(combined)
        }
        
        let personalReg = db.collection("users")
            .document(uid)
            .collection("expenses")
            .whereField("monthKey", isEqualTo: monthKey)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                personalExpenses = documents.compactMap { try? $0.data(as: Expense.self) }
                emitCombined()
            }
            
        let paidByReg = db.collection("shared_expenses")
            .whereField("monthKey", isEqualTo: monthKey)
            .whereField("paidByEmail", isEqualTo: email)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                // To avoid duplicates with sharedWithReg, we handle all updates in memory
                let fetched = documents.compactMap { try? $0.data(as: Expense.self) }
                let others = sharedExpenses.filter { $0.paidByEmail != email }
                sharedExpenses = fetched + others
                emitCombined()
            }
            
        let sharedWithReg = db.collection("shared_expenses")
            .whereField("monthKey", isEqualTo: monthKey)
            .whereField("sharedWithEmail", isEqualTo: email)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                let fetched = documents.compactMap { try? $0.data(as: Expense.self) }
                let others = sharedExpenses.filter { $0.sharedWithEmail != email }
                sharedExpenses = fetched + others
                emitCombined()
            }
            
        return [personalReg, paidByReg, sharedWithReg]
    }
}
