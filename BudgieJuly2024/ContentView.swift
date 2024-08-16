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
    @State private var showImproveBudgetPopup = false
    @State private var isSurplus = false
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

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        allocationListView()
                    }
                    .padding(.top, 16)
                }
                .background(Color.clear)

                Spacer()
                
                footerNavigationBar()
            }
            .environmentObject(budgetCategoryStore)
            .sheet(isPresented: $showCategorySelection) {
                // Show category selection view or any other view when the user clicks "Enhance"
            }
            .onAppear {
                formatAndCalculatePaycheckAmount()
                calculateBudget()
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showImproveBudgetPopup.toggle()
                            isSurplus = budgieModel.paycheckAmount > totalMonthlyBudget
                        }
                    }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // Raised slightly higher
                }
            }

            if showImproveBudgetPopup {
                ImproveBudgetPopup(isShowing: $showImproveBudgetPopup, selectedCategories: $selectedCategories, budgieModel: $budgieModel, isSurplus: isSurplus, budgetCategoryStore: budgetCategoryStore)
            }
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
    }

    private func allocationListView() -> some View {
        VStack(spacing: 16) {
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

            VStack(spacing: 0) {
                ForEach(selectedCategories) { category in
                    categoryView(category)
                    if category.id != selectedCategories.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(10)
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
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandedCategoryIndex = expandedCategoryIndex == category.id ? nil : category.id
                }
            }

            if expandedCategoryIndex == category.id {
                VStack(alignment: .leading, spacing: 8) {
                    if category.type == .saving || category.type == .debt {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(category.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                    }
                    
                    if category.type == .need || category.type == .want {
                        ForEach(category.subcategories.filter { $0.isSelected }) { subcategory in
                            subcategoryView(for: subcategory, in: category)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    private func subcategoryView(for subcategory: BudgetSubCategory, in category: BudgetCategory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(subcategory.name)
                    .font(.body)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: allocations[subcategory.id] ?? 0)) ?? "$0")")
                    .font(.body)
                    .foregroundColor(Color.primary)
                Image(systemName: expandedSubCategoryIndex == subcategory.id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandedSubCategoryIndex = expandedSubCategoryIndex == subcategory.id ? nil : subcategory.id
                }
            }

            if expandedSubCategoryIndex == subcategory.id {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(subcategory.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
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
        HStack(spacing: 70) {  // Increased spacing between the buttons
            footerButton(title: "Budget", icon: "list.bullet", isSelected: selectedTab == .budget) {
                selectedTab = .budget
                // Navigate to Budget view
            }
            footerButton(title: "Affordability", icon: "house", isSelected: selectedTab == .affordability) {
                selectedTab = .affordability
                // Navigate to Affordability view
            }
            footerButton(title: "Profile", icon: "person.circle", isSelected: selectedTab == .profile) {
                selectedTab = .profile
                // Navigate to Profile view
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
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
