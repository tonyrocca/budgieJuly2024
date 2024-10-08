import SwiftUI

struct AffordabilityView: View {
    @ObservedObject var budgetCategoryStore: BudgetCategoryStore
    @StateObject private var budgieModel: BudgieModel
    @State private var selectedTimeframe: Timeframe = .monthly

    init(paymentAmount: Double, paymentCadence: PaymentCadence) {
        self._budgieModel = StateObject(wrappedValue: BudgieModel(paycheckAmount: paymentAmount))
        self.budgetCategoryStore = BudgetCategoryStore.shared
        self.budgieModel.paymentCadence = paymentCadence
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                timeframePicker
                
                affordabilityItem(title: "House", value: calculateHouseAffordability(), description: "Based on 28% of income for mortgage")
                affordabilityItem(title: "Car", value: calculateCarAffordability(), description: "Based on 10% of income for car payment")
                affordabilityItem(title: "Emergency Savings", value: calculateEmergencySavings(), description: "3-6 months of expenses")
                affordabilityItem(title: "Dining Out", value: calculateDiningOut(), description: "Based on Food category allocation")
                affordabilityItem(title: "Vacation", value: calculateVacation(), description: "Based on Vacation savings category")
                affordabilityItem(title: "Wedding", value: calculateWedding(), description: "Based on Wedding savings category")
                affordabilityItem(title: "Clothing", value: calculateClothing(), description: "Based on Clothing Fund savings category")
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(radius: 5)
        }
        .navigationTitle("Affordability View")
        .onAppear {
            budgieModel.calculateAllocations(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected })
            budgieModel.calculateRecommendedAllocations(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected })
        }
    }

    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }

    private func affordabilityItem(title: String, value: Double, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: value)) ?? "$0")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }

    private func calculateHouseAffordability() -> Double {
        let monthlyIncome = budgieModel.adjustAmountForPaymentCadence(budgieModel.paycheckAmount)
        let houseAffordability = monthlyIncome * 0.28 * Double(selectedTimeframe.months)
        return houseAffordability
    }

    private func calculateCarAffordability() -> Double {
        let monthlyIncome = budgieModel.adjustAmountForPaymentCadence(budgieModel.paycheckAmount)
        let carAffordability = monthlyIncome * 0.10 * Double(selectedTimeframe.months)
        return carAffordability
    }

    private func calculateEmergencySavings() -> Double {
        if let emergencyFund = budgetCategoryStore.categories.first(where: { $0.name == "Emergency Fund" }) {
            return (budgieModel.recommendedAllocations[emergencyFund.id] ?? 0) * Double(selectedTimeframe.months)
        }
        return 0
    }

    private func calculateDiningOut() -> Double {
        if let foodCategory = budgetCategoryStore.categories.first(where: { $0.name == "Food" }),
           let diningOutSubcategory = foodCategory.subcategories.first(where: { $0.name == "Dining Out" }) {
            return (budgieModel.allocations[diningOutSubcategory.id] ?? 0) * Double(selectedTimeframe.months)
        }
        return 0
    }

    private func calculateVacation() -> Double {
        if let vacationCategory = budgetCategoryStore.categories.first(where: { $0.name == "Vacation" }) {
            return (budgieModel.recommendedAllocations[vacationCategory.id] ?? 0) * Double(selectedTimeframe.months)
        }
        return 0
    }

    private func calculateWedding() -> Double {
        if let weddingCategory = budgetCategoryStore.categories.first(where: { $0.name == "Wedding" }) {
            return (budgieModel.recommendedAllocations[weddingCategory.id] ?? 0) * 24 // Assuming 2 years of savings
        }
        return 0
    }

    private func calculateClothing() -> Double {
        if let clothingCategory = budgetCategoryStore.categories.first(where: { $0.name == "Clothing Fund" }) {
            return (budgieModel.recommendedAllocations[clothingCategory.id] ?? 0) * Double(selectedTimeframe.months)
        }
        return 0
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
}

enum Timeframe: String, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var months: Int {
        switch self {
        case .monthly: return 1
        case .quarterly: return 3
        case .yearly: return 12
        }
    }
}
