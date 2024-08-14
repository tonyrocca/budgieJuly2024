import SwiftUI
import Combine

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
    @State private var selectedViewOption: ViewOption = .yourBudget
    @State private var isActionButtonPressed = false

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
            NavigationView {
                VStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("Your Personalized Budget")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                            .foregroundColor(Color.primary)

                        HStack(spacing: 0) {
                            ForEach(ViewOption.allCases, id: \.self) { option in
                                ToggleButton(
                                    label: option.title,
                                    isSelected: selectedViewOption == option,
                                    action: { selectedViewOption = option }
                                )
                            }
                        }
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            GeometryReader { geometry in
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width / CGFloat(ViewOption.allCases.count), height: 2)
                                        .offset(x: geometry.size.width / CGFloat(ViewOption.allCases.count) * CGFloat(selectedViewOption.index))
                                }
                            }
                        )
                        .animation(.easeInOut, value: selectedViewOption)
                    }
                    .background(Color(UIColor.systemBackground))
                    .zIndex(1)

                    ScrollView {
                        VStack(spacing: 12) {
                            allocationListView()
                        }
                        .padding(.top, 16)
                    }
                    .background(Color.clear)

                    Spacer()
                }
                .navigationBarItems(trailing: EmptyView())
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(budgetCategoryStore)
                .sheet(isPresented: $showCategorySelection) {
                    // Show category selection view or any other view when the user clicks "Enhance"
                }
                .onAppear {
                    formatAndCalculatePaycheckAmount()
                    calculateBudget()
                }
            }
            .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))

            if isActionButtonPressed {
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 10)
                    
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            ActionButton(icon: "bolt.fill", label: "Enhance") {
                                // Action for enhance
                            }
                            ActionButton(icon: "person.crop.circle.fill", label: "Profile") {
                                // Action for profile
                            }
                            ActionButton(icon: "pencil", label: "Edit") {
                                // Action for edit
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Button(action: {
                            withAnimation {
                                isActionButtonPressed.toggle()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom))
                }
                .transition(.opacity)
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isActionButtonPressed.toggle()
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(category.emoji) \(category.name)")
                        .font(.body)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(currencyFormatter.string(from: NSNumber(value: allocations[category.id] ?? 0)) ?? "$0")")
                        .font(.body)
                        .foregroundColor(Color.primary)
                    Image(systemName: expandedCategoryIndex == category.id ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        expandedCategoryIndex = expandedCategoryIndex == category.id ? nil : category.id
                    }
                }

                if expandedCategoryIndex == category.id {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.darkGray))
                            Text(category.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)

                        if category.type == .saving {
                            savingsView(for: category)
                        } else {
                            ForEach(category.subcategories.filter { $0.isSelected }) { subcategory in
                                subcategoryView(for: subcategory, in: category)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }

        private func savingsView(for category: BudgetCategory) -> some View {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Monthly Savings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("\(currencyFormatter.string(from: NSNumber(value: category.amount ?? 0)) ?? "$0")")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            // Action to edit savings amount
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Allocation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Not yet calculated")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                }
            }
        }

        private func subcategoryView(for subcategory: BudgetSubCategory, in category: BudgetCategory) -> some View {
            VStack {
                HStack {
                    Text("\(subcategory.name)")
                        .font(.body)
                    Spacer()
                    Text("\(currencyFormatter.string(from: NSNumber(value: allocations[subcategory.id] ?? 0)) ?? "$0")")
                        .font(.body)
                        .foregroundColor(Color.primary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        expandedSubCategoryIndex = expandedSubCategoryIndex == subcategory.id ? nil : subcategory.id
                    }
                }

                if expandedSubCategoryIndex == subcategory.id {
                    Text(subcategory.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
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
}

struct ToggleButton: View {
    var label: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .blue : .gray)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
        }
    }
}

struct ActionButton: View {
    var icon: String
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundColor(.primary)
                    .font(.system(size: 18, weight: .medium))
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(30)
        }
    }
}

enum ViewOption: CaseIterable {
    case yourBudget
    case recommendedBudget
    case overview

    var title: String {
        switch self {
        case .yourBudget: return "Actual"
        case .recommendedBudget: return "Recommended"
        case .overview: return "Summary"
        }
    }

    var index: Int {
        switch self {
        case .yourBudget: return 0
        case .recommendedBudget: return 1
        case .overview: return 2
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selectedCategories: BudgetCategoryStore.shared.categories, paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
