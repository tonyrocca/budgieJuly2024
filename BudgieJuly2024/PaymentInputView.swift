import SwiftUI

struct PaymentInputView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var income: String = ""
    @State private var paymentFrequency: PaymentCadence?
    @State private var showPaymentFrequency = false
    @State private var showNextButton = false

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
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter gross income")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .foregroundColor(.primary)

                Text("Please enter your gross income per paycheck and how often you get paid.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }

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
                                ForEach(PaymentCadence.allCases, id: \.self) { frequency in
                                    Text(frequency.rawValue.capitalized)
                                        .tag(PaymentCadence?.some(frequency))
                                }
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

            Spacer()

            // Next button
            if showNextButton {
                NavigationLink(destination: DebtQuestionView(income: .constant(income), paymentFrequency: Binding(
                    get: { self.paymentFrequency ?? .monthly },
                    set: { self.paymentFrequency = $0 }
                )).environmentObject(budgetCategoryStore)) {
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
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
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
