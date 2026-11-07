import Foundation
import SwiftData

/// Persistent model storing user preferences, partner configuration, and financial defaults.
@Model
final class UserSettings {
    /// Unique identifier for the user settings profile.
    var id: UUID = UUID()
    
    /// Email of the logged-in user who owns these settings
    var ownerEmail: String = ""

    /// Standard ISO currency code (default: INR)
    var currencyCode: String = "INR"

    /// Currency symbol for display (default: ₹)
    var currencySymbol: String = "₹"

    /// Pre-fill suggestion for new months; auto-updates to last month's base salary
    var expectedMonthlySalary: Double = Constants.defaultExpectedSalary

    /// Default user fraction for shared expenses
    var defaultSplitRatio: Double = Constants.defaultSplitRatio


    /// Optional display name
    var userName: String = ""
    
    /// Email of the person to share expenses with by default
    var partnerEmail: String = ""
    
    /// Display name of the partner
    var partnerName: String = ""

    // MARK: - Monthly Reset Controls

    /// When false (default), the dashboard and analytics will NOT auto-reset
    /// when a new calendar month starts. The user must manually reset via
    /// the button in Settings. When true, the app auto-advances to the
    /// current calendar month on every launch.
    var autoResetEnabled: Bool = false

    /// The month key the dashboard is currently showing.
    /// Persisted so the app keeps displaying the same month's data
    /// even after a calendar rollover, until the user resets manually.
    var activeMonthKey: String = ""

    // MARK: - Init (all defaults)

    init() {
        self.id = UUID()
        self.currencyCode = "INR"
        self.currencySymbol = "₹"
        self.expectedMonthlySalary = Constants.defaultExpectedSalary
        self.defaultSplitRatio = Constants.defaultSplitRatio
        self.userName = ""
        self.autoResetEnabled = false
        self.activeMonthKey = DateHelpers.monthKey()
    }
}
