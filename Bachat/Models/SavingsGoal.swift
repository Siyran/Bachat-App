import Foundation
import SwiftData

@Model
final class SavingsGoal {
    var id: UUID = UUID()
    
    var ownerEmail: String = ""

    /// Human-readable name, e.g. "Sister's Wedding"
    var name: String = Constants.defaultGoalName

    /// Target amount in ₹
    var targetAmount: Double = Constants.defaultGoalAmount

    /// Deadline
    var targetDate: Date = {
        var c = DateComponents()
        c.year = 2027; c.month = 5; c.day = 31
        return Calendar.current.date(from: c)!
    }()

    /// Whether this goal is the active one
    var isActive: Bool = true

    var createdAt: Date = Date()

    // MARK: - Init

    init(
        name: String = Constants.defaultGoalName,
        targetAmount: Double = Constants.defaultGoalAmount,
        targetDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.targetAmount = targetAmount
        if let td = targetDate {
            self.targetDate = td
        } else {
            var c = DateComponents()
            c.year = 2027; c.month = 5; c.day = 31
            self.targetDate = Calendar.current.date(from: c)!
        }
        self.isActive = isActive
        self.createdAt = Date()
    }
}
