import Foundation
import SwiftData

@Model
final class SalaryAction {
    var id: UUID = UUID()

    /// Month this action belongs to, e.g. "2026-10"
    var monthKey: String = ""

    /// Type tag: "transfer_to_hdfc", "bonus_transfer", "top_up_hdfc"
    var actionType: String = ""

    /// Amount in ₹
    var amount: Double = 0

    /// Human-readable description, e.g. "Move ₹28,000 to HDFC"
    var label: String = ""

    /// Whether the user has completed this action
    var isCompleted: Bool = false

    var createdAt: Date = Date()

    // MARK: - Init

    init(monthKey: String, actionType: String, amount: Double, label: String) {
        self.id = UUID()
        self.monthKey = monthKey
        self.actionType = actionType
        self.amount = amount
        self.label = label
        self.isCompleted = false
        self.createdAt = Date()
    }
}
