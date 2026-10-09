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
