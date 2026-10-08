import Foundation
import SwiftData

@Model
final class IncomeEntry {
    var id: UUID = UUID()

    /// Amount of this income line item
    var amount: Double = 0

    /// Human-readable label, e.g. "Diwali Bonus", "October Tutoring"
    var label: String = ""

    /// Stored as the raw value of IncomeType
    var typeRaw: String = IncomeType.other.rawValue

    /// When this income was received
    var date: Date = Date()

    /// Whether the user has transferred the savings portion to HDFC
    var transferDone: Bool = false

    /// Inverse side of MonthlyIncome.extras
    var monthlyIncome: MonthlyIncome?

    // MARK: - Computed

    var type: IncomeType {
        get { IncomeType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    // MARK: - Init

    init(amount: Double, label: String, type: IncomeType, date: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.label = label
        self.typeRaw = type.rawValue
        self.date = date
        self.transferDone = false
    }
}
