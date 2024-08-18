import SwiftUI

struct ContentView: View {
    @StateObject private var budgetCategoryStore = BudgetCategoryStore.shared
    @State private var budgieModel: BudgieModel
    @State private var paycheckAmountText: String
    @State private var paycheckAmount: Double? = nil
    @State private var paymentCadence: PaymentCadence
    @State private var allocations: [UUID: Double] = [:]
    @State private var showDetails = false
    @State private var expandedCategoryIndex: UUID? = nil
    @State private var expandedSubCategoryIndex: UUID? = nil
    @State private var showCategorySelection = false
    @FocusState private var isInputFocused: Bool
    @State private var selectedTab: Tab = .budget
    @State private var selectedCategories: [BudgetCategory]

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
        self._selectedCategories = State(initialValue: selectedCategories)
    }

    var totalMonthlyBudget: Double {
        guard let amount = paycheckAmount else { return 0 }
        return paymentCadence.monthlyEquivalent(from: amount)
    }

    var totalPerPaycheckBudget: Double {
        guard let amount = paycheckAmount else { return 0 }
        return amount
    }
    
    var budgetDeficitOrSurplus: Double {
        let totalAllocated = allocations.values.reduce(0, +)
        return totalPerPaycheckBudget - totalAllocated
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 8) {
                        Color.clear.frame(height: 100)
                        allocationListView()
                    }
                    .padding(.top, 8)
                }
                .background(Color(UIColor.systemGroupedBackground))

                footerNavigationBar()
            }
            
            paycheckTotalView()
                .zIndex(1)
        }
        .environmentObject(budgetCategoryStore)
        .onAppear {
            formatAndCalculatePaycheckAmount()
            calculateBudget()
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
    }

    private func paycheckTotalView() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Paycheck Total")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: totalPerPaycheckBudget)) ?? "$0")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack {
                Text(budgetDeficitOrSurplus >= 0 ? "Surplus" : "Deficit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: abs(budgetDeficitOrSurplus))) ?? "$0")
                    .font(.headline)
                    .foregroundColor(budgetDeficitOrSurplus >= 0 ? .green : .red)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func allocationListView() -> some View {
        VStack(spacing: 12) {
            ForEach(selectedCategories) { category in
                categoryView(category)
            }
        }
        .padding(.horizontal)
    }
    
    private func categoryView(_ category: BudgetCategory) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(category.emoji) \(category.name)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: allocations[category.id] ?? 0)) ?? "$0")")
                    .font(.headline)
                    .foregroundColor(Color.primary)
                Image(systemName: expandedCategoryIndex == category.id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandedCategoryIndex = expandedCategoryIndex == category.id ? nil : category.id
                }
            }

            if expandedCategoryIndex == category.id {
                if category.type == .saving || category.type == .debt {
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        descriptionView(for: category)
                    }
                } else if category.type == .need || category.type == .want {
                    expenseCategoryView(for: category)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }

    private func expenseCategoryView(for category: BudgetCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(category.subcategories.filter { $0.isSelected }) { subcategory in
                subcategoryView(for: subcategory, in: category)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .transition(.opacity)
    }

    private func subcategoryView(for subcategory: BudgetSubCategory, in category: BudgetCategory) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(subcategory.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: allocations[subcategory.id] ?? 0)) ?? "$0")")
                    .font(.subheadline)
                    .foregroundColor(Color.primary)
                Image(systemName: expandedSubCategoryIndex == subcategory.id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.blue)
                    .font(.footnote)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandedSubCategoryIndex = expandedSubCategoryIndex == subcategory.id ? nil : subcategory.id
                }
            }

            if expandedSubCategoryIndex == subcategory.id {
                descriptionView(for: subcategory)
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private func descriptionView(for item: Any) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(description(for: item))
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
    }

    private func description(for item: Any) -> String {
        if let category = item as? BudgetCategory {
            return category.description
        } else if let subcategory = item as? BudgetSubCategory {
            return subcategory.description
        }
        return ""
    }

    private func formatAndCalculatePaycheckAmount() {
        let filteredText = paycheckAmountText.filter { "0123456789.".contains($0) }
        if let value = Double(filteredText) {
            paycheckAmount = value
            paycheckAmountText = currencyFormatter.string(from: NSNumber(value: value)) ?? ""
            showDetails = true
            budgieModel.paycheckAmount = value
            calculateBudget()
        } else {
            showDetails = false
        }
    }

    private func calculateBudget() {
        budgieModel.paymentCadence = paymentCadence
        budgieModel.calculateAllocations(selectedCategories: selectedCategories)
        allocations = budgieModel.allocations
    }

    private func footerNavigationBar() -> some View {
        HStack(spacing: 70) {
            footerButton(title: "Budget", icon: "list.bullet", isSelected: selectedTab == .budget) {
                selectedTab = .budget
            }
            footerButton(title: "Affordability", icon: "house", isSelected: selectedTab == .affordability) {
                selectedTab = .affordability
            }
            footerButton(title: "Profile", icon: "person.circle", isSelected: selectedTab == .profile) {
                selectedTab = .profile
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: -3)
        .clipShape(Capsule())
    }

    private func footerButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .gray)
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
    }

    enum Tab {
        case budget
        case affordability
        case profile
    }
}
