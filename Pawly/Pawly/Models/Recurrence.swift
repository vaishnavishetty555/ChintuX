import Foundation

/// PRD §6.3 — Recurrence options.
/// Stored as a single `String` on the Reminder model for SwiftData compatibility,
/// encoded/decoded via `rawString`.
enum Recurrence: Codable, Equatable, Hashable {
    case once
    case daily
    case everyNDays(Int)
    case weekly(weekdays: Set<Int>)  // 1 = Sunday ... 7 = Saturday (Calendar.weekday)
    case monthly(day: Int)           // day-of-month 1...28
    case everyNMonths(Int, day: Int) // e.g. every 3 months on the 15th

    // MARK: - String codec for SwiftData
    // Format examples:
    //   "once"
    //   "daily"
    //   "everyNDays:3"
    //   "weekly:1,3,5"
    //   "monthly:15"
    //   "everyNMonths:3:15"

    var rawString: String {
        switch self {
        case .once: return "once"
        case .daily: return "daily"
        case .everyNDays(let n): return "everyNDays:\(n)"
        case .weekly(let days):
            let sorted = days.sorted().map(String.init).joined(separator: ",")
            return "weekly:\(sorted)"
        case .monthly(let d): return "monthly:\(d)"
        case .everyNMonths(let n, let d): return "everyNMonths:\(n):\(d)"
        }
    }

    init?(rawString: String) {
        let parts = rawString.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard let head = parts.first else { return nil }
        switch head {
        case "once":  self = .once
        case "daily": self = .daily
        case "everyNDays":
            guard parts.count == 2, let n = Int(parts[1]), n > 0 else { return nil }
            self = .everyNDays(n)
        case "weekly":
            guard parts.count == 2 else { return nil }
            let days = parts[1].split(separator: ",").compactMap { Int($0) }
            guard !days.isEmpty, days.allSatisfy({ (1...7).contains($0) }) else { return nil }
            self = .weekly(weekdays: Set(days))
        case "monthly":
            guard parts.count == 2, let d = Int(parts[1]), (1...28).contains(d) else { return nil }
            self = .monthly(day: d)
        case "everyNMonths":
            guard parts.count == 3, let n = Int(parts[1]), n > 0,
                  let d = Int(parts[2]), (1...28).contains(d) else { return nil }
            self = .everyNMonths(n, day: d)
        default: return nil
        }
    }

    var displayDescription: String {
        switch self {
        case .once: return "Once"
        case .daily: return "Every day"
        case .everyNDays(let n): return n == 1 ? "Every day" : "Every \(n) days"
        case .weekly(let days):
            let names = days.sorted().map { Self.weekdayShort($0) }.joined(separator: ", ")
            return "Weekly on \(names)"
        case .monthly(let d): return "Monthly on day \(d)"
        case .everyNMonths(let n, let d): return "Every \(n) months on day \(d)"
        }
    }

    static func weekdayShort(_ idx: Int) -> String {
        let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        let clamped = max(1, min(7, idx))
        return names[clamped - 1]
    }
}
