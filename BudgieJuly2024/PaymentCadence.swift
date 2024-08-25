import Foundation

enum PaymentCadence: String, CaseIterable, Codable {
    case monthly = "Monthly"
    case biWeekly = "Bi-Weekly"
    case weekly = "Weekly"
    case semiMonthly = "Semi-Monthly"  // New case

    func monthlyEquivalent(from amount: Double) -> Double {
        switch self {
        case .monthly:
            return amount
        case .biWeekly:
            return amount * 2
        case .weekly:
            return amount * 4
        case .semiMonthly:
            return amount * 2  // Semi-monthly is paid twice per month
        }
    }

    var numberOfPaychecksPerMonth: Double {
        switch self {
        case .monthly:
            return 1
        case .biWeekly:
            return 2
        case .weekly:
            return 4
        case .semiMonthly:
            return 2  // Two paychecks per month for semi-monthly
        }
    }
}
