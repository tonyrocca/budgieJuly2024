import SwiftUI

struct AffordabilityView: View {
    @ObservedObject var budgieModel: BudgieModel
    @State private var expandedItem: AffordabilityItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {  // Reduced spacing between cards
                ForEach(AffordabilityItem.allCases, id: \.self) { item in
                    affordabilityCard(item: item)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }

    private func affordabilityCard(item: AffordabilityItem) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(item.emoji)
                    .font(.system(size: 20))  // Slightly reduced emoji size
                Text(item.title)
                    .font(.headline)
                Spacer()
                Image(systemName: expandedItem == item ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))  // Smaller chevron
            }
            .padding(.horizontal)
            .padding(.vertical, 8)  // Reduced vertical padding
            .background(Color(UIColor.secondarySystemBackground))
            .onTapGesture {
                withAnimation {
                    expandedItem = expandedItem == item ? nil : item
                }
            }
            
            // Main Content
            HStack {
                Text(currencyFormatter.string(from: NSNumber(value: item.calculateAmount(annualIncome: calculateAnnualIncome()))) ?? "$0")
                    .font(.system(size: 24, weight: .bold, design: .rounded))  // Smaller font size
                    .foregroundColor(.primary)  // Changed to black
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)  // Reduced vertical padding
            .background(Color(UIColor.systemBackground))
            
            // Expandable Content
            if expandedItem == item {
                VStack(alignment: .leading, spacing: 8) {  // Reduced spacing
                    Text("Estimated \(item.name) savings based on your income:")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("How it's calculated:")
                        .font(.footnote)
                        .fontWeight(.medium)
                    
                    ForEach(item.assumptions, id: \.self) { assumption in
                        HStack(alignment: .top, spacing: 6) {  // Reduced spacing
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(item.color)
                                .font(.system(size: 12))  // Smaller checkmark
                            Text(assumption)
                                .font(.footnote)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .transition(.opacity)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)  // Slightly reduced corner radius
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)  // Subtle shadow
    }

    private func calculateAnnualIncome() -> Double {
        budgieModel.paymentCadence.monthlyEquivalent(from: budgieModel.paycheckAmount) * 12
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
}

// The AffordabilityItem enum remains unchanged

enum AffordabilityItem: CaseIterable {
    case house, car, vacation, wedding, education, retirement, emergencyFund

    var name: String {
        switch self {
        case .house: return "home"
        case .car: return "car"
        case .vacation: return "vacation"
        case .wedding: return "wedding"
        case .education: return "education"
        case .retirement: return "retirement"
        case .emergencyFund: return "emergency fund"
        }
    }

    var emoji: String {
        switch self {
        case .house: return "🏠"
        case .car: return "🚗"
        case .vacation: return "✈️"
        case .wedding: return "💍"
        case .education: return "🎓"
        case .retirement: return "🏖️"
        case .emergencyFund: return "🆘"
        }
    }

    var title: String {
        switch self {
        case .house: return "Home Affordability"
        case .car: return "Car Affordability"
        case .vacation: return "Vacation Savings"
        case .wedding: return "Wedding Budget"
        case .education: return "Education Fund"
        case .retirement: return "Retirement Savings"
        case .emergencyFund: return "Emergency Fund"
        }
    }

    var color: Color {
        switch self {
        case .house: return .blue
        case .car: return .green
        case .vacation: return .orange
        case .wedding: return .pink
        case .education: return .purple
        case .retirement: return .red
        case .emergencyFund: return .yellow
        }
    }

    func calculateAmount(annualIncome: Double) -> Double {
        switch self {
        case .house:
            return annualIncome * 3 // 3x annual income
        case .car:
            return annualIncome * 0.35 // 35% of annual income
        case .vacation:
            return annualIncome * 0.05 // 5% of annual income
        case .wedding:
            return annualIncome * 0.5 // 50% of annual income
        case .education:
            return annualIncome * 2 // 2x annual income (for a 4-year degree)
        case .retirement:
            return annualIncome * 10 // 10x annual income (rough estimate)
        case .emergencyFund:
            return annualIncome * 0.5 // 6 months of income
        }
    }

    var assumptions: [String] {
        switch self {
        case .house:
            return [
                "Based on 3x your annual income",
                "Assumes a 20% down payment",
                "Considers a 30-year fixed-rate mortgage",
                "Doesn't include property taxes or insurance"
            ]
        case .car:
            return [
                "Based on 35% of your annual income",
                "Assumes a 4-year loan term",
                "Doesn't include insurance or maintenance costs"
            ]
        case .vacation:
            return [
                "Estimates 5% of your annual income for vacation savings",
                "Actual costs may vary based on destination and travel style",
                "Consider saving this amount annually for vacations"
            ]
        case .wedding:
            return [
                "Suggests a budget of 50% of your annual income",
                "National average wedding cost is around $30,000",
                "Adjust based on your preferences and guest count"
            ]
        case .education:
            return [
                "Estimates total cost at 2x your annual income",
                "Based on average 4-year college costs",
                "Includes tuition, room, and board",
                "Actual costs vary by institution and location"
            ]
        case .retirement:
            return [
                "Rough estimate of 10x your annual income",
                "Actual needs may vary based on lifestyle and retirement age",
                "Consider consulting a financial advisor for personalized planning"
            ]
        case .emergencyFund:
            return [
                "Recommends saving 6 months of income",
                "Covers unexpected expenses or loss of income",
                "Adjust based on job security and personal circumstances"
            ]
        }
    }
}
