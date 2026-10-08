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
