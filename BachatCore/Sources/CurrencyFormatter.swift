import Foundation

enum CurrencyFormatter {

    /// Format a Double as INR with Indian grouping: ₹1,00,000
    static func format(_ amount: Double, symbol: String = "₹", showPaise: Bool = false) -> String {
        let isNegative = amount < 0
        let absAmount = abs(amount)

        let integerPart = Int(absAmount)
        let decimalPart = absAmount - Double(integerPart)

        let grouped = formatIndianGrouping(integerPart)

        var result = "\(symbol)\(grouped)"

        if showPaise {
            let paise = Int((decimalPart * 100).rounded())
            result += String(format: ".%02d", paise)
        }

        return isNegative ? "-\(result)" : result
    }

    /// Indian-style grouping: last three digits, then groups of two
    /// e.g. 300000 → "3,00,000"
    private static func formatIndianGrouping(_ number: Int) -> String {
        if number < 1_000 {
            return "\(number)"
        }

        let lastThree = number % 1_000
        var remaining = number / 1_000
        var groups: [String] = [String(format: "%03d", lastThree)]

        while remaining > 0 {
            let group = remaining % 100
            remaining /= 100
            if remaining > 0 {
                groups.append(String(format: "%02d", group))
            } else {
                groups.append("\(group)")
            }
        }

        return groups.reversed().joined(separator: ",")
    }

    /// Compact Indian format: ₹3L, ₹40K, ₹1.5Cr
    static func compact(_ amount: Double, symbol: String = "₹") -> String {
        let absAmount = abs(amount)
        let sign = amount < 0 ? "-" : ""

        if absAmount >= 1_00_00_000 {
            let cr = absAmount / 1_00_00_000
            let formatted = cr.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", cr) : String(format: "%.1f", cr)
            return "\(sign)\(symbol)\(formatted)Cr"
        } else if absAmount >= 1_00_000 {
            let lakh = absAmount / 1_00_000
            let formatted = lakh.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", lakh) : String(format: "%.1f", lakh)
            return "\(sign)\(symbol)\(formatted)L"
        } else if absAmount >= 1_000 {
            let k = absAmount / 1_000
            let formatted = k.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", k) : String(format: "%.1f", k)
            return "\(sign)\(symbol)\(formatted)K"
        } else {
            return "\(sign)\(symbol)\(Int(absAmount))"
        }
    }
}
