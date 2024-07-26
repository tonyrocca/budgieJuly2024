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

    private let currentYear = Calendar.current.component(.year, from: Date())
    private var years: [Int]

    init(income: Binding<String>, paymentFrequency: Binding<PaymentCadence>, hasExpenses: Bool, hasSavingsGoals: Bool) {
        self._income = income
        self._paymentFrequency = paymentFrequency
        self.hasExpenses = hasExpenses
        self.hasSavingsGoals = hasSavingsGoals
        self.years = Array(currentYear...currentYear + 10)
    }

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter your debt details")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)

            Text("Enter your debt amount and when it is due.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(budgetCategoryStore.categories.filter { $0.type == .debt && $0.isSelected }) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(category.emoji) \(category.name)")
                                    .font(.headline)
                                Spacer()
                            }

                            HStack {
                                Text("$")
                                    .padding(.leading, 16)
                                TextField("Enter your debt amount", text: Binding(
                                    get: { debtAmounts[category.id] ?? "" },
                                    set: { debtAmounts[category.id] = $0 }
                                ))
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(12)
                                .background(Color(UIColor.systemGray5))
                                .cornerRadius(8)
                                .keyboardType(.decimalPad)
                                .onChange(of: debtAmounts[category.id] ?? "") { newValue in
                                    debtAmounts[category.id] = formatCurrencyInput(newValue)
                                }
                                .multilineTextAlignment(.trailing)
                                .padding(.trailing, 16)
                                
                                Button(action: {
                                    if showDatePicker == category.id {
                                        showDatePicker = nil
                                    } else {
                                        showDatePicker = category.id
                                    }
                                }) {
                                    Image(systemName: "calendar")
                                        .padding(.trailing, 16)
                                }
                            }
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)

                            if showDatePicker == category.id {
                                DatePicker(
                                    "Select Due Date",
                                    selection: Binding(
                                        get: { selectedDates[category.id] ?? Date() },
                                        set: { selectedDates[category.id] = $0 }
                                    ),
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .labelsHidden()
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                }
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
                    .padding(.horizontal)
                    .shadow(radius: 5)
            }
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    private func formatCurrencyInput(_ input: String) -> String {
        let filtered = input.filter { "0123456789".contains($0) }
        if let value = Double(filtered) {
            return String(format: "%.2f", value / 100)
        }
        return ""
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
}

struct DebtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DebtDetailView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasExpenses: true, hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
