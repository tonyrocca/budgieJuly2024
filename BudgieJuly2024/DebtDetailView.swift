import SwiftUI

struct DebtDetailView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var hasExpenses: Bool
    var hasSavingsGoals: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    @State private var debtAmounts: [UUID: Double] = [:]
    @State private var selectedDates: [UUID: Date] = [:]
    @State private var showDatePicker: UUID? = nil

    private let currentYear = Calendar.current.component(.year, from: Date())
    private var years: [Int]

    init(income: Binding<String>, paymentFrequency: Binding<PaymentCadence>, hasExpenses: Bool, hasSavingsGoals: Bool) {
        self._income = income
        self._paymentFrequency = paymentFrequency
        self.hasExpenses = hasExpenses
        self.hasSavingsGoals = hasSavingsGoals
        self.years = Array(currentYear...currentYear + 10)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter debt details")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .foregroundColor(.primary)
                
                Text("Enter your total debt amount owed and when it is due.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Debt Categories
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(budgetCategoryStore.categories.filter { $0.type == .debt && $0.isSelected }) { category in
                        DebtCategoryView(category: category, debtAmounts: $debtAmounts, selectedDates: $selectedDates, showDatePicker: $showDatePicker)
                        if category.id != budgetCategoryStore.categories.filter({ $0.type == .debt && $0.isSelected }).last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal, 16)
            }

            Spacer()

            NavigationLink(destination: nextView()) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 50)
            .disabled(!isFormComplete())
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .onAppear {
            initializeFields()
        }
        .onDisappear {
            saveFields()
        }
    }

    private func nextView() -> some View {
        if hasExpenses {
            return AnyView(ExpenseSelectionView(income: $income, paymentFrequency: $paymentFrequency, hasSavingsGoals: hasSavingsGoals)
                .environmentObject(budgetCategoryStore))
        } else if hasSavingsGoals {
            return AnyView(SavingsSelectionView(income: $income, paymentFrequency: $paymentFrequency)
                .environmentObject(budgetCategoryStore))
        } else {
            return AnyView(ContentView(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected }, paymentFrequency: paymentFrequency, paycheckAmountText: income)
                .environmentObject(budgetCategoryStore))
        }
    }

    private func isFormComplete() -> Bool {
        return budgetCategoryStore.categories.filter { $0.type == .debt && $0.isSelected }.allSatisfy {
            (debtAmounts[$0.id] ?? 0.0) > 0 && selectedDates[$0.id] != nil
        }
    }

    private func initializeFields() {
        for category in budgetCategoryStore.categories.filter({ $0.type == .debt && $0.isSelected }) {
            debtAmounts[category.id] = category.amount ?? 0.0
            selectedDates[category.id] = category.dueDate ?? Date()
        }
    }

    private func saveFields() {
        for category in budgetCategoryStore.categories.filter({ $0.type == .debt && $0.isSelected }) {
            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                budgetCategoryStore.categories[index].amount = debtAmounts[category.id]
                budgetCategoryStore.categories[index].dueDate = selectedDates[category.id] ?? Date()
            }
        }
    }
}

struct DebtCategoryView: View {
    var category: BudgetCategory
    @Binding var debtAmounts: [UUID: Double]
    @Binding var selectedDates: [UUID: Date]
    @Binding var showDatePicker: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(category.emoji) \(category.name)")
                .font(.headline)
                .foregroundColor(.primary)

            CurrencyTextField(value: Binding(
                get: { debtAmounts[category.id] ?? 0.0 },
                set: { debtAmounts[category.id] = $0 }
            ))
            .frame(height: 44)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)

            HStack {
                Text("When is the debt due?")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text(selectedDates[category.id]?.formatted(.dateTime.year().month().day()) ?? Date().formatted(.dateTime.year().month().day()))
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            .onTapGesture {
                showDatePicker = (showDatePicker == category.id) ? nil : category.id
            }

            if showDatePicker == category.id {
                DatePicker(
                    "Select Due Date",
                    selection: Binding(
                        get: { selectedDates[category.id] ?? Date() },
                        set: { selectedDates[category.id] = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

struct DebtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DebtDetailView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasExpenses: true, hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
