import SwiftUI

struct AffordabilityView: View {
    @ObservedObject var budgieModel: BudgieModel
    @State private var expandedItem: AffordabilityItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                affordabilityCard(item: .house)
                affordabilityCard(item: .car)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func affordabilityCard(item: AffordabilityItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.emoji)
                    .font(.system(size: 24))
                Text(item.title)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: expandedItem == item ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)
            
            Text("Below is the amount of \(item.name) you can afford based on your income:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(currencyFormatter.string(from: NSNumber(value: item.calculateAffordability(annualIncome: calculateAnnualIncome()))) ?? "$0")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(item.color)
            
            if expandedItem == item {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it's calculated:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(item.assumptions, id: \.self) { assumption in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(item.color)
                                .font(.system(size: 12))
                            Text(assumption)
                                .font(.subheadline)
                        }
                    }
                }
                .transition(.opacity)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onTapGesture {
            withAnimation {
                if expandedItem == item {
                    expandedItem = nil
                } else {
                    expandedItem = item
                }
            }
        }
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

enum AffordabilityItem {
    case house
    case car

    var name: String {
        switch self {
        case .house: return "home"
        case .car: return "car"
        }
    }

    var emoji: String {
        switch self {
        case .house: return "🏠"
        case .car: return "🚗"
        }
    }

    var title: String {
        switch self {
        case .house: return "Home Affordability"
        case .car: return "Car Affordability"
        }
    }

    var color: Color {
        switch self {
        case .house: return .blue
        case .car: return .green
        }
    }

    func calculateAffordability(annualIncome: Double) -> Double {
        switch self {
        case .house:
            return annualIncome * 3 // Typically, you can afford a house 3x your annual income
        case .car:
            return annualIncome * 0.35 // You can typically afford a car worth 35% of your annual income
        }
    }

    var assumptions: [String] {
        switch self {
        case .house:
            return [
                "Based on 3x your annual income",
                "Assumes a 20% down payment",
                "Considers a 30-year fixed-rate mortgage",
                "Doesn't include property taxes or insurance",
                "Actual affordability may vary based on other factors"
            ]
        case .car:
            return [
                "Based on 35% of your annual income",
                "Assumes a 4-year loan term",
                "Doesn't include insurance or maintenance costs",
                "Consider your other expenses when deciding on a car budget"
            ]
        }
    }
}
