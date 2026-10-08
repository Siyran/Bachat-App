import Foundation
import SwiftUI

// MARK: - Expense Category

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case groceries          = "Groceries"
    case foodAndEatingOut   = "Food & Eating Out"
    case transport          = "Transport"
    case household          = "Household"
    case phoneAndInternet   = "Phone & Internet"
    case personal           = "Personal"
    case exploring          = "Hyderabad Exploring"
    case sharedWithRoommate = "Shared with Roommate"
    case travelHome         = "Travel Home (Kashmir)"
    case misc               = "Misc"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .groceries:          return "cart.fill"
        case .foodAndEatingOut:   return "fork.knife"
        case .transport:          return "bus.fill"
        case .household:          return "house.fill"
        case .phoneAndInternet:   return "wifi"
        case .personal:           return "person.fill"
        case .exploring:          return "map.fill"
        case .sharedWithRoommate: return "person.2.fill"
        case .travelHome:         return "airplane"
        case .misc:               return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .groceries:          return .green
        case .foodAndEatingOut:   return .orange
        case .transport:          return .blue
        case .household:          return .purple
        case .phoneAndInternet:   return .cyan
        case .personal:           return .pink
        case .exploring:          return .mint
        case .sharedWithRoommate: return .indigo
        case .travelHome:         return .teal
        case .misc:               return .gray
        }
    }
}

// MARK: - Income Type

enum IncomeType: String, Codable, CaseIterable, Identifiable {
    case bonus      = "Bonus"
    case arrears    = "Arrears"
    case honorarium = "Honorarium"
    case sideIncome = "Side Income"
    case other      = "Other"

    var id: String { rawValue }

    /// True for extras that are NOT side income (bonuses, arrears, honorarium, etc.)
    var isExtra: Bool {
        self != .sideIncome
    }
}

// MARK: - Savings Rule

enum SavingsRule: String, Codable, CaseIterable, Identifiable {
    case fixedLimit     = "Fixed Spending Limit"
    case savePercentage = "Save a Percentage"

    var id: String { rawValue }
}

// MARK: - Alert Level

enum AlertLevel: String, Sendable {
    case safe
    case caution
    case overLimit

    var color: Color {
        switch self {
        case .safe:      return .green
        case .caution:   return .orange
        case .overLimit: return .red
        }
    }
}

// MARK: - Goal Status

enum GoalStatus: String, Sendable {
    case ahead   = "Ahead"
    case onTrack = "On Track"
    case behind  = "Behind"

    var color: Color {
        switch self {
        case .ahead:   return .green
        case .onTrack: return .blue
        case .behind:  return .red
        }
    }

    var icon: String {
        switch self {
        case .ahead:   return "arrow.up.circle.fill"
        case .onTrack: return "checkmark.circle.fill"
        case .behind:  return "exclamationmark.triangle.fill"
        }
    }
}
