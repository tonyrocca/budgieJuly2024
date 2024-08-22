import SwiftUI

struct DebtDetailView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var hasExpenses: Bool
    var hasSavings: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    @State private var debtAmounts: [UUID: String] = [:]
    @State private var selectedDates: [UUID: Date] = [:]
    @State private var showDatePicker: UUID? = nil

    private let currentDate = Date()
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month], from: currentDate)
        guard let start = calendar.date(from: startComponents) else { return currentDate...currentDate }
        let endComponents = DateComponents(year: startComponents.year! + 10, month: 12)
        guard let end = calendar.date(from: endComponents) else { return currentDate...currentDate }
        return start...end
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter debt details")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Enter your total debt amount owed and when it is due.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .padding(.horizontal, 16)

            // Debt Categories
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(budgetCategoryStore.categories.filter { $0.type == .debt && $0.isSelected }) { category in
                        DebtCategoryView(
                            category: category,
                            debtAmount: binding(for: category.id),
                            selectedDate: Binding(
                                get: { self.selectedDates[category.id] ?? self.defaultDate() },
                                set: { self.selectedDates[category.id] = $0 }
                            ),
                            showDatePicker: $showDatePicker,
                            dateRange: dateRange
                        )
                    }
                }
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

    private func binding(for id: UUID) -> Binding<String> {
        return Binding(
            get: { self.debtAmounts[id] ?? "" },
            set: { self.debtAmounts[id] = $0 }
        )
    }

    private func defaultDate() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        components.month! += 1
        return calendar.date(from: components) ?? currentDate
    }

    private func nextView() -> some View {
        ExpenseQuestionView(income: $income, paymentFrequency: $paymentFrequency, hasDebt: true)
            .environmentObject(budgetCategoryStore)
    }

    private func isFormComplete() -> Bool {
        return budgetCategoryStore.categories.filter { $0.type == .debt && $0.isSelected }.allSatisfy {
            let amount = debtAmounts[$0.id] ?? ""
            return !amount.isEmpty && Double(amount) ?? 0 > 0 && selectedDates[$0.id] != nil
        }
    }

    private func initializeFields() {
        for category in budgetCategoryStore.categories.filter({ $0.type == .debt && $0.isSelected }) {
            if let amount = category.amount {
                debtAmounts[category.id] = String(format: "%.0f", amount)
            } else {
                debtAmounts[category.id] = ""
            }
            selectedDates[category.id] = category.dueDate ?? defaultDate()
        }
    }

    private func saveFields() {
        for category in budgetCategoryStore.categories.filter({ $0.type == .debt && $0.isSelected }) {
            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                budgetCategoryStore.categories[index].amount = Double(debtAmounts[category.id] ?? "0")
                budgetCategoryStore.categories[index].dueDate = selectedDates[category.id] ?? defaultDate()
            }
        }
    }
}

struct DebtCategoryView: View {
    var category: BudgetCategory
    @Binding var debtAmount: String
    @Binding var selectedDate: Date
    @Binding var showDatePicker: UUID?
    var dateRange: ClosedRange<Date>

    private let inputBackgroundColor = Color(UIColor.systemGray6)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.name)
                .font(.headline)
            
            HStack {
                Text("Amount:")
                TextField("Enter amount", text: $debtAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                Text("Due date:")
                Text(selectedDate, style: .date)
                Spacer()
                Button(action: {
                    showDatePicker = showDatePicker == category.id ? nil : category.id
                }) {
                    Image(systemName: "calendar")
                }
            }
            
            if showDatePicker == category.id {
                DatePicker("Select date", selection: Binding(
                    get: { self.selectedDate },
                    set: { self.selectedDate = $0 }
                ), in: dateRange, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}
