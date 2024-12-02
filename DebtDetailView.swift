import SwiftUI

struct DebtDetailView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var hasExpenses: Bool
    var hasSavings: Bool
    var hasBudgetingExperience: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)

    @State private var debtAmounts: [UUID: String] = [:]
    @State private var selectedDates: [UUID: Date] = [:]
    @State private var showDatePicker: UUID? = nil

    private let currentDate = Date()
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfMonth(for: currentDate)
        let endComponents = DateComponents(year: calendar.component(.year, from: start) + 10, month: 12)
        let end = calendar.date(from: endComponents) ?? start
        return start...end
    }

    // Updated nextView function to always go to ExpenseQuestionView
    private func nextView() -> some View {
        return AnyView(ExpenseQuestionView(
            income: $income,
            paymentFrequency: $paymentFrequency,
            hasDebt: true,
            hasBudgetingExperience: hasBudgetingExperience
        ).environmentObject(budgetCategoryStore))
    }

    // Rest of the view implementation remains the same...
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

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(budgetCategoryStore.categories.filter { $0.type == .debt && $0.isSelected }) { category in
                        VStack(spacing: 0) {
                            // Category Header
                            HStack {
                                Text(category.emoji)
                                Text(category.name)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(lightGreen)

                            // Amount and Date inputs
                            VStack(spacing: 12) {
                                // Amount Input
                                HStack {
                                    Text("Amount:")
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    HStack {
                                        Text("$")
                                            .foregroundColor(.primary)
                                        TextField("0", text: binding(for: category.id))
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 100)
                                    }
                                    .padding(8)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                }

                                // Due Date Input
                                HStack {
                                    Text("Due date:")
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Button(action: {
                                        showDatePicker = showDatePicker == category.id ? nil : category.id
                                    }) {
                                        Text(monthYearFormatter.string(from: selectedDates[category.id] ?? defaultDate()))
                                            .foregroundColor(.primary)
                                        Image(systemName: "calendar")
                                    }
                                    .padding(8)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                }

                                if showDatePicker == category.id {
                                    MonthYearPickerView(
                                        selection: Binding(
                                            get: { self.selectedDates[category.id] ?? self.defaultDate() },
                                            set: {
                                                self.selectedDates[category.id] = $0
                                                self.showDatePicker = nil
                                            }
                                        ),
                                        range: dateRange
                                    )
                                    .frame(height: 200)
                                    .transition(.opacity)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
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
                    .background(customGreen)
                    .cornerRadius(10)
                    .shadow(color: customGreen.opacity(0.3), radius: 5)
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

    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

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

// MonthYearPickerView

struct MonthYearPickerView: View {
    @Binding var selection: Date
    let range: ClosedRange<Date>
    
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    
    init(selection: Binding<Date>, range: ClosedRange<Date>) {
        self._selection = selection
        self.range = range
        
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.month, .year], from: selection.wrappedValue)
        self._selectedMonth = State(initialValue: currentComponents.month ?? 1)
        self._selectedYear = State(initialValue: currentComponents.year ?? 2024)
    }
    
    var body: some View {
        HStack {
            Picker("Month", selection: $selectedMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text(DateFormatter().monthSymbols[month - 1]).tag(month)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: 150)
            .clipped()
            
            Picker("Year", selection: $selectedYear) {
                ForEach(Array(range.lowerBound.year...range.upperBound.year), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: 100)
            .clipped()
        }
        .onChange(of: selectedMonth) { _ in updateDate() }
        .onChange(of: selectedYear) { _ in updateDate() }
    }
    
    private func updateDate() {
        let calendar = Calendar.current
        if let newDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) {
            selection = newDate
        }
    }
}

extension Date {
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
}

// Extension for Calendar to get the start of the month

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }
}
