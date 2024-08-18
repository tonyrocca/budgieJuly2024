import SwiftUI

struct DebtDetailView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var hasExpenses: Bool
    var hasSavingsGoals: Bool
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

    @State private var selectedMonth: Int
    @State private var selectedYear: Int

    private let inputBackgroundColor = Color(UIColor.systemGray6)
    private let calendarIcon = Image(systemName: "calendar")

    init(category: BudgetCategory, debtAmount: Binding<String>, selectedDate: Binding<Date>, showDatePicker: Binding<UUID?>, dateRange: ClosedRange<Date>) {
        self.category = category
        self._debtAmount = debtAmount
        self._selectedDate = selectedDate
        self._showDatePicker = showDatePicker
        self.dateRange = dateRange

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: selectedDate.wrappedValue)
        _selectedMonth = State(initialValue: components.month ?? 1)
        _selectedYear = State(initialValue: components.year ?? calendar.component(.year, from: Date()))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(category.emoji) \(category.name)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                HStack {
                    Text("$")
                        .foregroundColor(.primary)
                    TextField("0", text: $debtAmount)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: debtAmount) { newValue in
                            debtAmount = formatCurrencyInput(newValue)
                        }
                }
                .padding(8)
                .background(inputBackgroundColor)
                .cornerRadius(8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("When is the debt due?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(monthName(selectedMonth)) \(String(selectedYear))")
                    Spacer()
                    calendarIcon
                }
                .font(.subheadline)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(inputBackgroundColor)
                .cornerRadius(8)
                .onTapGesture {
                    showDatePicker = (showDatePicker == category.id) ? nil : category.id
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)

            if showDatePicker == category.id {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(monthName(month)).tag(month)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        .clipped()

                        Picker("Year", selection: $selectedYear) {
                            ForEach(Calendar.current.component(.year, from: dateRange.lowerBound)...Calendar.current.component(.year, from: dateRange.upperBound), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        .clipped()
                    }
                    .onChange(of: selectedMonth) { _ in updateSelectedDate() }
                    .onChange(of: selectedYear) { _ in updateSelectedDate() }

                    Button(action: {
                        showDatePicker = nil
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                .padding(.vertical, 16)
                .background(inputBackgroundColor)
                .cornerRadius(12)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }

    private func formatCurrencyInput(_ input: String) -> String {
        let filtered = input.filter { "0123456789".contains($0) }
        if let value = Double(filtered) {
            return String(format: "%.0f", value)
        }
        return ""
    }

    private func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.monthSymbols[month - 1]
    }

    private func updateSelectedDate() {
        var dateComponents = DateComponents()
        dateComponents.year = selectedYear
        dateComponents.month = selectedMonth
        dateComponents.day = 1
        if let newDate = Calendar.current.date(from: dateComponents) {
            selectedDate = newDate
        }
    }
}

struct DebtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DebtDetailView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasExpenses: true, hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
