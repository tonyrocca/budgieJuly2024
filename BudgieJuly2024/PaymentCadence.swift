import Foundation

enum PaymentCadence: String, CaseIterable {
    case monthly = "Monthly"
    case biWeekly = "Bi-Weekly"
    case weekly = "Weekly"

    func monthlyEquivalent(from amount: Double) -> Double {
        switch self {
        case .monthly:
            return amount
        case .biWeekly:
            return amount * 2
        case .weekly:
            return amount * 4
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
        }
    }
}
