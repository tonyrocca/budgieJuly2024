import SwiftUI

struct RecommendedBudgetView: View {
    @StateObject private var budgetCategoryStore = BudgetCategoryStore.shared
    @State private var budgieModel: BudgieModel
    @State private var paycheckAmountText: String
    @State private var paymentCadence: PaymentCadence
    @State private var recommendedAllocations: [UUID: Double] = [:]

    var selectedCategories: [BudgetCategory]

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    init(selectedCategories: [BudgetCategory], paymentFrequency: PaymentCadence, paycheckAmountText: String) {
        self._paymentCadence = State(initialValue: paymentFrequency)
        self._paycheckAmountText = State(initialValue: paycheckAmountText)
        self._budgieModel = State(initialValue: BudgieModel(paycheckAmount: Double(paycheckAmountText) ?? 0.0))
        self.selectedCategories = selectedCategories
        self.calculateRecommendedBudget()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended Budget")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        .foregroundColor(Color.primary)
                }
                .background(Color(UIColor.systemBackground))
                .zIndex(1)

                ScrollView {
                    VStack(spacing: 12) {
                        allocationListView()
                            .padding(.horizontal)
                    }
                    .padding(.top, 16)
                }
                .background(Color.clear)
            }
            .navigationBarHidden(true)
            .environmentObject(budgetCategoryStore)
            .onAppear {
                calculateRecommendedBudget()
            }
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
    }

    private func allocationListView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Paycheck Total")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: totalPerPaycheckBudget)) ?? "$0")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(selectedCategories) { category in
                VStack {
                    categoryView(category)
                }
                Divider()
            }
        }
        .padding()
    }

    private func categoryView(_ category: BudgetCategory) -> some View {
        VStack {
            HStack {
                Text("\(category.emoji) \(category.name)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(backgroundColor(for: category))
                    .cornerRadius(8)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: recommendedAllocations[category.id] ?? 0)) ?? "$0")")
                    .font(.body)
                    .foregroundColor(Color.primary)
            }
            .padding(.vertical, 6)
        }
    }

    private func calculateRecommendedBudget() {
        let monthlyPaycheck = paymentCadence.monthlyEquivalent(from: budgieModel.paycheckAmount)

        for category in selectedCategories {
            if category.type == .saving {
                let savingsAmount = calculateSavingsAmount(for: category.name, monthlyPaycheck: monthlyPaycheck)
                recommendedAllocations[category.id] = savingsAmount
            } else {
                recommendedAllocations[category.id] = calculateRecommendedAmount(for: category)
            }
        }
    }

    private func calculateSavingsAmount(for categoryName: String, monthlyPaycheck: Double) -> Double {
        let savingsPercentages: [String: Double] = [
            "Emergency Fund": 0.10,
            "Vacation": 0.05,
            "New Car": 0.05,
            "Home Renovation": 0.07,
            "Investment": 0.10,
            "Wedding": 0.05,
            "Education Fund": 0.05
        ]

        return monthlyPaycheck * (savingsPercentages[categoryName] ?? 0.05)
    }

    private func calculateRecommendedAmount(for category: BudgetCategory) -> Double {
        // Implement your best principles logic here.
        return 0.0 // Placeholder
    }

    private func backgroundColor(for category: BudgetCategory) -> Color {
        switch category.type {
        case .debt:
            return Color.red.opacity(0.1)
        case .need:
            return Color.yellow.opacity(0.1)
        case .saving:
            return Color.green.opacity(0.1)
        default:
            return Color.clear
        }
    }
    
    private var totalPerPaycheckBudget: Double {
        guard let amount = Double(paycheckAmountText) else { return 0 }
        return amount
    }
}
