import Foundation
import SwiftData

@Model
final class MonthlyIncome {
    var id: UUID = UUID()

    /// Canonical month identifier, e.g. "2026-10"
    var monthKey: String = ""
    
    var ownerEmail: String = ""

    /// Base salary credited this month
    var baseSalary: Double = 0

    /// Bonuses, arrears, side income, etc.
    @Relationship(deleteRule: .cascade, inverse: \IncomeEntry.monthlyIncome)
    var extras: [IncomeEntry] = []

    /// True until the user confirms income for this month
    var isProvisional: Bool = true
    
    /// Optional date when salary was credited
    var creditedDate: Date? = nil

    // MARK: - Computed

    var totalIncome: Double {
        baseSalary + extras.reduce(0) { $0 + $1.amount }
    }

    /// Sum of extras that are NOT side income (bonuses, arrears, honorarium, etc.)
    var bonusTotal: Double {
        extras.filter { $0.type != .sideIncome }.reduce(0) { $0 + $1.amount }
    }

    /// Sum of side-income entries
    var sideIncomeTotal: Double {
        extras.filter { $0.type == .sideIncome }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Init

    init(monthKey: String, baseSalary: Double, isProvisional: Bool = true) {
        self.id = UUID()
        self.monthKey = monthKey
        self.baseSalary = baseSalary
        self.extras = []
        self.isProvisional = isProvisional
    }
}
