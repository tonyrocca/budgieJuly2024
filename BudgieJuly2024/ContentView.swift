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
                        // Header
                        Text("Your Personalized Budget")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                            .foregroundColor(Color.primary)

                        // Toggle Buttons
                        HStack(spacing: 0) {
                            ToggleButton(label: "Actual", isSelected: selectedViewOption == .yourBudget) {
                                selectedViewOption = .yourBudget
                            }
                            ToggleButton(label: "Recommended", isSelected: selectedViewOption == .recommendedBudget) {
                                selectedViewOption = .recommendedBudget
                            }
                            ToggleButton(label: "Summary", isSelected: selectedViewOption == .overview) {
                                selectedViewOption = .overview
                            }
                        }
                        .frame(height: 40)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
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

                    HStack {
                        Spacer()
                    }
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
                Color.white.opacity(0.8).edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        ActionButton(icon: "sparkles", label: "Enhance") {
                            // Action for enhance
                        }
                        ActionButton(icon: "person.crop.circle", label: "Profile") {
                            // Action for profile
                        }
                        ActionButton(icon: "pencil", label: "Edit") {
                            // Action for edit
                        }
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "xmark")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                            )
                            .onTapGesture {
                                withAnimation {
                                    isActionButtonPressed.toggle()
                                }
                            }
                    }
                    .padding(.bottom, 40)
                    .padding(.trailing, 20)
                }
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                            )
                            .onTapGesture {
                                withAnimation {
                                    isActionButtonPressed.toggle()
                                }
                            }
                            .padding(.bottom, 40)
                            .padding(.trailing, 20)
                    }
                }
            }
        }
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
                    .cornerRadius(8)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: allocations[category.id] ?? 0)) ?? "$0")")
                    .font(.body)
                    .foregroundColor(Color.primary)
                Button(action: {
                    withAnimation {
                        expandedCategoryIndex = expandedCategoryIndex == category.id ? nil : category.id
                    }
                }) {
                    Image(systemName: expandedCategoryIndex == category.id ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 6)

            if expandedCategoryIndex == category.id {
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    ForEach(category.subcategories.filter { $0.isSelected }) { subcategory in
                        subcategoryView(for: subcategory, in: category)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
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
                Button(action: {
                    withAnimation {
                        expandedSubCategoryIndex = expandedSubCategoryIndex == subcategory.id ? nil : subcategory.id
                    }
                }) {
                    Image(systemName: expandedSubCategoryIndex == subcategory.id ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 6)

            if expandedSubCategoryIndex == subcategory.id {
                VStack(alignment: .leading, spacing: 8) {
                    Text(subcategory.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
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
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color.clear)
                .cornerRadius(isSelected ? 10 : 0)
        }
    }
}

struct ActionButton: View {
    var icon: String
    var label: String
    var action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                HStack {
                    Image(systemName: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                    Text(label)
                        .font(.body)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
        }
    }
}

enum ViewOption {
    case yourBudget
    case recommendedBudget
    case overview
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selectedCategories: BudgetCategoryStore.shared.categories, paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
