import Foundation
import FirebaseFirestore

struct Expense: Identifiable, Codable {
    var id: String


    /// User's share of the expense (after split if shared)
    var amount: Double = 0

    /// Full amount before any split (equals `amount` when not shared)
    var fullAmount: Double = 0

    /// Stored as the raw value of ExpenseCategory
    var categoryRaw: String = ExpenseCategory.misc.rawValue

    /// Optional free-text note
    var note: String = ""

    /// When the expense occurred
    var date: Date = Date()

    /// Whether this expense is split with the roommate
    var isShared: Bool = false

    /// User's fraction of a shared expense (0.0–1.0). Always 1.0 when not shared.
    var splitRatio: Double = 1.0

    /// Fast-lookup key such as "2026-10"
    var monthKey: String = ""
    
    /// Email of the user who paid
    var paidByEmail: String = ""
    
    /// Email of the roommate (if shared)
    var sharedWithEmail: String = ""

    // MARK: - Computed

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .misc }
        set { categoryRaw = newValue.rawValue }
    }

    /// Amount the roommate owes (zero when not shared)
    var roommateShare: Double {
        isShared ? fullAmount - amount : 0
    }

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        amount: Double,
        category: ExpenseCategory,
        note: String = "",
        date: Date = Date(),
        isShared: Bool = false,
        splitRatio: Double = 0.5,
        paidByEmail: String = "",
        sharedWithEmail: String = ""
    ) {
        self.id = id
        self.categoryRaw = category.rawValue
        self.note = note
        self.date = date
        self.isShared = isShared
        self.fullAmount = amount
        self.splitRatio = isShared ? splitRatio : 1.0
        self.amount = isShared ? (amount * splitRatio) : amount
        self.monthKey = DateHelpers.monthKey(for: date)
        self.paidByEmail = paidByEmail
        self.sharedWithEmail = sharedWithEmail
    }
}
