import Foundation

enum DateHelpers {
    private static let calendar = Calendar.current

    // MARK: - Month Key

    /// Canonical key for a month, e.g. "2026-10"
    static func monthKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    /// Parse a month key back into a Date (1st of that month, midnight)
    static func date(from monthKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: monthKey)
    }

    /// The month key for the month before `key`
    static func previousMonthKey(from key: String) -> String? {
        guard let d = date(from: key),
              let prev = calendar.date(byAdding: .month, value: -1, to: d) else { return nil }
        return monthKey(for: prev)
    }

    /// The month key for the month after `key`
    static func nextMonthKey(from key: String) -> String? {
        guard let d = date(from: key),
              let next = calendar.date(byAdding: .month, value: 1, to: d) else { return nil }
        return monthKey(for: next)
    }

    // MARK: - Day Counts

    /// Total days in the month containing `date`
    static func daysInMonth(for date: Date = Date()) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    /// 1-based day-of-month
    static func dayOfMonth(for date: Date = Date()) -> Int {
        calendar.component(.day, from: date)
    }

    /// Days remaining in the month **including today**
    static func daysLeftInMonth(for date: Date = Date()) -> Int {
        let total = daysInMonth(for: date)
        let current = dayOfMonth(for: date)
        return max(total - current + 1, 1)
    }

    /// Days elapsed in the month (1-based, so the 1st returns 1)
    static func daysElapsedInMonth(for date: Date = Date()) -> Int {
        dayOfMonth(for: date)
    }

    // MARK: - Month Boundaries

    /// Midnight on the 1st of the month containing `date`
    static func startOfMonth(for date: Date = Date()) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }

    /// End of the last day of the month containing `date`
    static func endOfMonth(for date: Date = Date()) -> Date {
        let start = startOfMonth(for: date)
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
    }

    // MARK: - Ranges

    /// Whole months between two dates (start-of-month to start-of-month)
    static func monthsBetween(from: Date, to: Date) -> Int {
        let comps = calendar.dateComponents([.month],
            from: startOfMonth(for: from),
            to: startOfMonth(for: to))
        return max(comps.month ?? 0, 0)
    }

    /// Calendar days between two dates (start-of-day to start-of-day)
    static func daysBetween(from: Date, to: Date) -> Int {
        let comps = calendar.dateComponents([.day],
            from: calendar.startOfDay(for: from),
            to: calendar.startOfDay(for: to))
        return max(comps.day ?? 0, 0)
    }

    // MARK: - Predicates

    static func isFirstOfMonth(for date: Date = Date()) -> Bool {
        dayOfMonth(for: date) == 1
    }

    static func isWeekend(_ date: Date) -> Bool {
        calendar.isDateInWeekend(date)
    }

    /// All month keys from `startKey` up to and including `endKey`
    static func monthKeys(from startKey: String, through endKey: String) -> [String] {
        guard var current = date(from: startKey),
              let end = date(from: endKey) else { return [] }
        var keys: [String] = []
        while current <= end {
            keys.append(monthKey(for: current))
            guard let next = calendar.date(byAdding: .month, value: 1, to: current) else { break }
            current = next
        }
        return keys
    }
}
import Foundation
import UIKit

struct PDFGenerator {
    static func generateSettleUpPDF(expenses: [Expense], month: String, net: Double, partnerName: String, userName: String, isYouOwe: Bool, userEmail: String) -> Data {
        let fmt = UIMarkupTextPrintFormatter(markupText: generateHTML(expenses: expenses, month: month, net: net, partnerName: partnerName, userName: userName, isYouOwe: isYouOwe, userEmail: userEmail))
        
        let render = UIPrintPageRenderer()
        render.addPrintFormatter(fmt, startingAtPageAt: 0)
        
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        render.setValue(NSValue(cgRect: page), forKey: "paperRect")
        render.setValue(NSValue(cgRect: page), forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, page, nil)
        
        for i in 0..<render.numberOfPages {
            UIGraphicsBeginPDFPage()
            render.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
    
    private static func generateHTML(expenses: [Expense], month: String, net: Double, partnerName: String, userName: String, isYouOwe: Bool, userEmail: String) -> String {
        var html = """
        <html>
        <head>
        <style>
            body { font-family: -apple-system, sans-serif; padding: 40px; color: #333; }
            h1 { color: #111; text-align: center; margin-bottom: 5px; }
            h2 { text-align: center; color: #666; margin-top: 0; }
            .summary { background-color: #f8f9fa; padding: 20px; border-radius: 10px; margin: 30px 0; text-align: center; }
            .summary-title { font-size: 18px; color: #555; }
            .summary-amount { font-size: 32px; font-weight: bold; color: \(isYouOwe ? "#dc3545" : "#28a745"); margin: 10px 0; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
            th { background-color: #f1f1f1; font-weight: 600; }
            .text-right { text-align: right; }
        </style>
        </head>
        <body>
            <h1>Expense Settlement</h1>
            <h2>Month: \(month)</h2>
            
            <div class="summary">
                <div class="summary-title">\(isYouOwe ? "You owe \(partnerName)" : "\(partnerName) owes you")</div>
                <div class="summary-amount">\(CurrencyFormatter.format(abs(net)))</div>
                <div>Settlement between <strong>\(userName)</strong> and <strong>\(partnerName)</strong></div>
            </div>
            
            <h3>Shared Expenses Breakdown</h3>
            <table>
                <tr>
                    <th>Date</th>
                    <th>Category</th>
                    <th>Note</th>
                    <th>Paid By</th>
                    <th class="text-right">Total Amount</th>
                    <th class="text-right">Amount Owed</th>
                </tr>
        """
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        for exp in expenses {
            let isPaidByMe = exp.paidByEmail.lowercased() == userEmail.lowercased()
            let payerName = isPaidByMe ? userName : partnerName
            
            // If I paid, my roommate owes me their share
            // If they paid, I owe them my share (which is exp.amount)
            let owedAmt = isPaidByMe ? exp.roommateShare : exp.amount
            
            html += """
                <tr>
                    <td>\(formatter.string(from: exp.date))</td>
                    <td>\(exp.category.rawValue)</td>
                    <td>\(exp.note)</td>
                    <td>\(payerName)</td>
                    <td class="text-right">\(CurrencyFormatter.format(exp.fullAmount))</td>
                    <td class="text-right" style="color: \(isPaidByMe ? "#28a745" : "#dc3545");">
                        \(isPaidByMe ? "+" : "-")\(CurrencyFormatter.format(owedAmt))
                    </td>
                </tr>
            """
        }
        
        html += """
            </table>
        </body>
        </html>
        """
        return html
    }
}
