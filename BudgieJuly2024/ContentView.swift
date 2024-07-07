import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var budgetCategoryStore = BudgetCategoryStore.shared
    @State private var budgieModel: BudgieModel
    @State private var paycheckAmountText: String
    @State private var paycheckAmount: Double? = nil
    @State private var paymentCadence: PaymentCadence
    @State private var allocations: [(key: String, value: Double)] = []
    @State private var showDetails = false
    @State private var expandedCategoryIndex: UUID? = nil
    @State private var expandedSubCategoryIndex: UUID? = nil
    @State private var showCategorySelection = false
    @State private var showPredefinedSubcategorySelection = false
    @State private var showAddSubcategoryForm = false
    @State private var newSubcategoryName = ""
    @State private var newSubcategoryAmount = ""
    @State private var newSubcategoryDescription = ""
    @State private var currentCategoryIndex: Int?
    @FocusState private var isInputFocused: Bool
    @State private var selectedViewOption: BudgetViewOption = .totalMonthly

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    init(paymentFrequency: PaymentCadence, paycheckAmountText: String) {
        self._paymentCadence = State(initialValue: paymentFrequency)
        self._paycheckAmountText = State(initialValue: paycheckAmountText)
        self._budgieModel = State(initialValue: BudgieModel(paycheckAmount: 0.0))
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
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("Your Personalized Budget")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                }
                .background(Color.white)
                .zIndex(1)

                ScrollView {
                    VStack(spacing: 12) {
                        allocationListView()
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    .padding(.top, 16)
                }
                .background(Color.clear)

                HStack {
                    Spacer()
                    Button(action: {
                        showCategorySelection = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarHidden(true)
            .environmentObject(budgetCategoryStore)
            .sheet(isPresented: $showCategorySelection) {
                // Here you can show the category selection view or any other view you want to display when the user clicks "Add Categories"
            }
            .sheet(isPresented: $showPredefinedSubcategorySelection) {
                predefinedSubcategorySelection()
            }
            .sheet(isPresented: $showAddSubcategoryForm) {
                addSubcategoryForm()
            }
            .onAppear {
                formatAndCalculatePaycheckAmount()
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
            .background(Color(UIColor.systemGray5))
            .cornerRadius(10)

            ForEach(budgetCategoryStore.categories) { category in
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
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: allocations.first(where: { $0.key == category.name })?.value ?? 0)) ?? "$0")")
                    .font(.body)
                    .foregroundColor(.black)
                Button(action: {
                    withAnimation {
                        expandedCategoryIndex = expandedCategoryIndex == category.id ? nil : category.id
                    }
                }) {
                    Image(systemName: expandedCategoryIndex == category.id ? "chevron.up" : "chevron.down")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 6)

            if expandedCategoryIndex == category.id {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(category.subcategories) { subcategory in
                        subcategoryView(for: subcategory, in: category)
                    }
                    addSubcategoryButton(for: category)
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
                Text("\(currencyFormatter.string(from: NSNumber(value: subcategory.allocationPercentage * totalMonthlyBudget)) ?? "$0")")
                    .font(.body)
                    .foregroundColor(.black)
                Button(action: {
                    withAnimation {
                        expandedSubCategoryIndex = expandedSubCategoryIndex == subcategory.id ? nil : subcategory.id
                    }
                }) {
                    Image(systemName: expandedSubCategoryIndex == subcategory.id ? "chevron.up" : "chevron.down")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 6)

            if expandedSubCategoryIndex == subcategory.id {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.black)
                    TextEditor(text: Binding(
                        get: { subcategory.description },
                        set: { newValue in
                            if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                if let subIndex = budgetCategoryStore.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                    budgetCategoryStore.categories[categoryIndex].subcategories[subIndex].description = newValue
                                }
                            }
                        }
                    ))
                    .frame(height: 60)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)

                    Text("Subcategory Amount")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.black)
                    TextField("Amount", value: Binding(
                        get: { subcategory.allocationPercentage * totalMonthlyBudget },
                        set: { newValue in
                            if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                if let subIndex = budgetCategoryStore.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                    budgetCategoryStore.categories[categoryIndex].subcategories[subIndex].allocationPercentage = newValue / totalMonthlyBudget
                                }
                            }
                        }
                    ), formatter: currencyFormatter)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)

                    Button(action: {
                        if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                            budgetCategoryStore.deleteSubCategory(from: categoryIndex, subcategory: subcategory)
                        }
                    }) {
                        Text("Delete")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    private func addSubcategoryButton(for category: BudgetCategory) -> some View {
        Button(action: {
            if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                currentCategoryIndex = categoryIndex
                showPredefinedSubcategorySelection = true
            }
        }) {
            HStack {
                Text("Add Subcategory")
                Spacer()
                Text("Add")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.2))
        .cornerRadius(10)
    }

    private func predefinedSubcategorySelection() -> some View {
        VStack {
            Text("Select Subcategory")
                .font(.title2)
                .bold()
                .padding()

            List {
                ForEach(availableSubcategories()) { subcategory in
                    Button(action: {
                        if let index = currentCategoryIndex {
                            budgetCategoryStore.addSubCategory(to: index, subcategory: subcategory)
                            showPredefinedSubcategorySelection = false
                        }
                    }) {
                        HStack {
                            Text(subcategory.name)
                            Spacer()
                        }
                    }
                }

                Button(action: {
                    showAddSubcategoryForm = true
                }) {
                    HStack {
                        Text("Build Your Own")
                        Spacer()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }

    private func availableSubcategories() -> [BudgetSubCategory] {
        if let categoryIndex = currentCategoryIndex {
            let existingSubcategoryNames = Set(budgetCategoryStore.categories[categoryIndex].subcategories.map { $0.name })
            let allSubcategories = predefinedSubcategories(for: budgetCategoryStore.categories[categoryIndex].name)
            return allSubcategories.filter { !existingSubcategoryNames.contains($0.name) }
        }
        return []
    }

    private func predefinedSubcategories(for categoryName: String) -> [BudgetSubCategory] {
        switch categoryName {
        case "Housing":
            return [
                BudgetSubCategory(name: "Mortgage", allocationPercentage: 0.0, description: ""),
                BudgetSubCategory(name: "Rent", allocationPercentage: 0.0, description: ""),
                BudgetSubCategory(name: "Utilities", allocationPercentage: 0.0, description: ""),
                BudgetSubCategory(name: "HOA Fee", allocationPercentage: 0.0, description: ""),
                BudgetSubCategory(name: "Home Maintenance", allocationPercentage: 0.0, description: "")
            ]
        case "Transportation":
            return [
                BudgetSubCategory(name: "Car Payment", allocationPercentage: 0.0, description: ""),
                BudgetSubCategory(name: "Public Transportation", allocationPercentage: 0.0, description: ""),
                BudgetSubCategory(name: "Ride Share", allocationPercentage: 0.0, description: ""),
                BudgetSubCategory(name: "Tolls", allocationPercentage: 0.0, description: ""),
                BudgetSubCategory(name: "Maintenance", allocationPercentage: 0.0, description: "")
            ]
        case "Goals":
            return [
                BudgetSubCategory(name: "Emergency Fund", allocationPercentage: 0.0, description: "Savings for emergencies."),
                BudgetSubCategory(name: "Vacation", allocationPercentage: 0.0, description: "Savings for a vacation."),
                BudgetSubCategory(name: "New Car", allocationPercentage: 0.0, description: "Savings for a new car.")
            ]
        default:
            return []
        }
    }

    private func addSubcategoryForm() -> some View {
        VStack {
            Text("Add New Subcategory")
                .font(.title2)
                .bold()
                .padding()

            TextField("Name", text: $newSubcategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Amount", text: $newSubcategoryAmount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Description", text: $newSubcategoryDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                if let index = currentCategoryIndex {
                    let amount = Double(newSubcategoryAmount) ?? 0.0
                    let newSubcategory = BudgetSubCategory(name: newSubcategoryName, allocationPercentage: amount / totalMonthlyBudget, description: newSubcategoryDescription)
                    budgetCategoryStore.addSubCategory(to: index, subcategory: newSubcategory)
                    showAddSubcategoryForm = false
                }
            }) {
                Text("Add")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
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
        budgieModel.calculateAllocations()
        allocations = budgieModel.sortedAllocations
    }
}

enum BudgetViewOption: String {
    case totalMonthly = "Total Monthly Budget"
    case perPaycheck = "Per Paycheck View"
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
