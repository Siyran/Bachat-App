import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID = UUID()
    
    /// Email of the logged-in user who owns these settings
    var ownerEmail: String = ""

    var currencyCode: String = "INR"
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

    // MARK: - Init (all defaults)

    init() {
        self.id = UUID()
        self.currencyCode = "INR"
        self.currencySymbol = "₹"
        self.expectedMonthlySalary = Constants.defaultExpectedSalary
        self.defaultSplitRatio = Constants.defaultSplitRatio
        self.userName = ""
    }
}
