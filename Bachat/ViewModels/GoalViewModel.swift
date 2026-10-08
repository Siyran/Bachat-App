import SwiftUI
import SwiftData
import FirebaseAuth

@MainActor
final class GoalViewModel: ObservableObject {
    private var modelContext: ModelContext
    
    init(context: ModelContext) {
        self.modelContext = context
    }
    
    func fetchOrCreateGoal() -> SavingsGoal {
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let descriptor = FetchDescriptor<SavingsGoal>(predicate: #Predicate { $0.ownerEmail == currentUserEmail })
        if let existing = try? modelContext.fetch(descriptor).first {
            if existing.name == "Sister's Wedding" {
                existing.name = "Savings Goal"
                try? modelContext.save()
            }
            return existing
        }
        
        let newGoal = SavingsGoal(targetAmount: 3_00_000)
        newGoal.ownerEmail = currentUserEmail
        modelContext.insert(newGoal)
        try? modelContext.save()
        return newGoal
    }
    
    func saveGoal() {
        try? modelContext.save()
    }
}
