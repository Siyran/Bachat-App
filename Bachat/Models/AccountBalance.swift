import Foundation
import SwiftData

/// Persistent entity representing a financial bank account balance with minimum floor tracking.
@Model
final class AccountBalance {
    /// Unique identifier for the account balance record.
    var id: UUID = UUID()
    
    /// User identifier owning this account.
    var ownerEmail: String = ""

    /// Account name, e.g. "HDFC", "ICICI"
    var name: String = ""

    /// Current balance in ₹
    var balance: Double = 0

    /// Floor that must be maintained (₹10,000 for HDFC, 0 for ICICI)
    var minimumBalance: Double = 0

    var lastUpdated: Date = Date()

    // MARK: - Computed

    var isBelowMinimum: Bool {
        balance < minimumBalance
    }

    var topUpNeeded: Double {
        max(minimumBalance - balance, 0)
    }

    // MARK: - Init

    init(name: String, balance: Double, minimumBalance: Double = 0) {
        self.id = UUID()
        self.name = name
        self.balance = balance
        self.minimumBalance = minimumBalance
        self.lastUpdated = Date()
    }
}
