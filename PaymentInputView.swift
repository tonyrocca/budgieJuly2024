import SwiftUI

struct PaymentInputView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var income: String = ""
    @State private var paymentFrequency: PaymentCadence?
    @State private var showPaymentFrequency = false
    @State private var showNextButton = false
    @State private var isInfoExpanded = false
    var hasBudgetingExperience: Bool

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enter gross income")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Please enter your gross income per paycheck and how often you get paid.")
                            .font(.headline)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                    // Income input
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("$")
                                .padding(.leading, 16)
                                .foregroundColor(.primary)
                            TextField("Enter gross income per paycheck", text: $income)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(12)
                                .background(Color(UIColor.systemGray5))
                                .cornerRadius(8)
                                .keyboardType(.numberPad)
                                .onChange(of: income) { newValue in
                                    income = formatCurrencyInput(newValue)
                                    if !income.isEmpty {
                                        showPaymentFrequency = true
                                    }
                                    checkShowNextButton()
                                }
                                .multilineTextAlignment(.trailing)
                                .padding(.trailing, 16)
                        }
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)

                    // Payment frequency input
                    if showPaymentFrequency {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Menu {
                                    Picker("How often are you paid?", selection: $paymentFrequency) {
                                        Text("Weekly").tag(PaymentCadence?.some(.weekly))
                                        Text("Bi-Weekly").tag(PaymentCadence?.some(.biWeekly))
                                        Text("Semi-Monthly").tag(PaymentCadence?.some(.semiMonthly))
                                        Text("Monthly").tag(PaymentCadence?.some(.monthly))
                                    }
                                } label: {
                                    HStack {
                                        Text(paymentFrequency?.rawValue.capitalized ?? "How often do you get paid?")
                                            .foregroundColor(paymentFrequency == nil ? .secondary : .primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.primary)
                                    }
                                    .padding(12)
                                    .background(Color(UIColor.systemGray5))
                                    .cornerRadius(8)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .onChange(of: paymentFrequency) { _ in
                                checkShowNextButton()
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Information Dropdown
                    infoDropdown
                }
            }

            Spacer()

            // Next button
            if showNextButton {
                NavigationLink(destination: DebtQuestionView(income: .constant(income), paymentFrequency: Binding(
                    get: { self.paymentFrequency ?? .monthly },
                    set: { self.paymentFrequency = $0 }
                ), hasBudgetingExperience: hasBudgetingExperience).environmentObject(budgetCategoryStore)) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.0, green: 0.27, blue: 0.0)) // Replace with your custom green
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 50)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    private var infoDropdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isInfoExpanded.toggle()
                }
            }) {
                HStack {
                    Text("What is Gross Income?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: isInfoExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)

            if isInfoExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gross income is the total amount of money you earn before taxes and other deductions are taken out.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("It includes:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Wages or salary")
                        bulletPoint("Bonuses and commissions")
                        bulletPoint("Overtime pay")
                        bulletPoint("Tips (if applicable)")
                        bulletPoint("Other forms of compensation")
                    }

                    Text("Example: If your salary is $50,000 per year and you receive a $2,000 bonus, your gross income would be $52,000.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Gross income is used to calculate your tax obligations and is typically higher than your take-home pay (net income).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .transition(.opacity)
            }
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func formatCurrencyInput(_ input: String) -> String {
        let filtered = input.filter { "0123456789".contains($0) }
        if let value = Double(filtered) {
            return String(format: "%.0f", value)
        }
        return ""
    }

    private func checkShowNextButton() {
        if !income.isEmpty, paymentFrequency != nil {
            showNextButton = true
        } else {
            showNextButton = false
        }
    }
}
