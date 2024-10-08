import SwiftUI

struct AffordabilityView: View {
    @ObservedObject var budgieModel: BudgieModel
    @State private var expandedItem: AffordabilityItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                affordabilityCard(
                    item: .house,
                    title: "Home Affordability",
                    value: calculateHouseAffordability(),
                    description: "Based on 28% of income for mortgage",
                    color: .blue
                )

                affordabilityCard(
                    item: .car,
                    title: "Car Affordability",
                    value: calculateCarAffordability(),
                    description: "Based on 10% of income for car payment",
                    color: .green
                )
            }
            .padding()
        }
        .navigationTitle("Affordability")
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func affordabilityCard(item: AffordabilityItem, title: String, value: Double, description: String, color: Color) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: value)) ?? "$0")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            .padding()
            .background(Color(UIColor.systemBackground))

            if expandedItem == item {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Assumptions:")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(item.assumptions, id: \.self) { assumption in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .padding(.top, 6)
                            Text(assumption)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .transition(.opacity)
            }
        }
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

    private func calculateHouseAffordability() -> Double {
        let annualIncome = calculateAnnualIncome()
        return annualIncome * 3 // Typically, you can afford a house 3x your annual income
    }

    private func calculateCarAffordability() -> Double {
        let annualIncome = calculateAnnualIncome()
        return annualIncome * 0.35 // You can typically afford a car worth 35% of your annual income
    }

    private func calculateAnnualIncome() -> Double {
        let monthlyIncome = budgieModel.paymentCadence.monthlyEquivalent(from: budgieModel.paycheckAmount)
        return monthlyIncome * 12
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

    var assumptions: [String] {
        switch self {
        case .house:
            return [
                "28% of gross monthly income for mortgage payments",
                "20% down payment",
                "30-year fixed-rate mortgage at current market rates",
                "Property taxes and insurance are not included",
                "Does not account for other debts or expenses"
            ]
        case .car:
            return [
                "10% of gross monthly income for car payments",
                "5-year loan term",
                "Average interest rate for new car loans",
                "20% down payment",
                "Does not include insurance, maintenance, or fuel costs"
            ]
        }
    }
}
