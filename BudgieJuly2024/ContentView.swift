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
    @State private var isEditing = false
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

                VStack(spacing: 12) {
                    Picker("", selection: $selectedViewOption) {
                        Text("Per Month").tag(BudgetViewOption.totalMonthly)
                        Text("Per Paycheck").tag(BudgetViewOption.perPaycheck)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Button(action: {
                        showCategorySelection = true
                    }) {
                        Text("Add Categories")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .environmentObject(budgetCategoryStore)
            .sheet(isPresented: $showCategorySelection) {
                // Here you can show the category selection view or any other view you want to display when the user clicks "Add Categories"
            }
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            isEditing = false
                        }
                    }
                }
            }
            .onAppear {
                formatAndCalculatePaycheckAmount()
            }
        }
    }

    private func allocationListView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedViewOption == .totalMonthly ? "Monthly Total" : "Paycheck Total")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: selectedViewOption == .totalMonthly ? totalMonthlyBudget : totalPerPaycheckBudget)) ?? "$0")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(UIColor.systemGray5))
            .cornerRadius(10)

            ForEach(budgetCategoryStore.categories) { category in
                VStack {
                    HStack {
                        Text("\(category.emoji) \(category.name)")
                            .font(.body)
                        Spacer()
                        if selectedViewOption == .totalMonthly {
                            Text("\(currencyFormatter.string(from: NSNumber(value: allocations.first(where: { $0.key == category.name })?.value ?? 0)) ?? "$0")")
                                .font(.body)
                                .foregroundColor(.black)
                        } else {
                            let perPaycheckAmount = (allocations.first(where: { $0.key == category.name })?.value ?? 0) / paymentCadence.numberOfPaychecksPerMonth
                            Text("\(currencyFormatter.string(from: NSNumber(value: perPaycheckAmount)) ?? "$0")")
                                .font(.body)
                                .foregroundColor(.black)
                        }
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
                                                    if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                                        if let subIndex = budgetCategoryStore.categories[index].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                                            budgetCategoryStore.categories[index].subcategories[subIndex].description = newValue
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
                                                    if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                                        if let subIndex = budgetCategoryStore.categories[index].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                                            budgetCategoryStore.categories[index].subcategories[subIndex].allocationPercentage = newValue / totalMonthlyBudget
                                                        }
                                                    }
                                                }
                                            ), formatter: currencyFormatter)
                                                .keyboardType(.decimalPad)
                                                .padding(8)
                                                .background(Color(UIColor.systemGray5))
                                                .cornerRadius(8)
                                        }
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(10)
                                    }
                                }
                                .background(Color(UIColor.systemGray6).opacity(0.2))
                                Divider()
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                    }
                }
                Divider()
            }
        }
        .padding()
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
