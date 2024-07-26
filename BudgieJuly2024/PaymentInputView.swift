import SwiftUI

struct PaymentInputView: View {
    @State private var income: String = ""
    @State private var paymentFrequency: PaymentCadence = .monthly

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
            Text("How much do you make when you get paid?")
                .font(.headline)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 32)

            HStack {
                Text("$")
                    .padding(.leading, 16)
                TextField("Enter your income", text: $income)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
                    .keyboardType(.decimalPad)
                    .onChange(of: income) { newValue in
                        income = formatCurrencyInput(newValue)
                    }
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing, 16)
            }
            .background(Color(UIColor.systemGray5))
            .cornerRadius(8)
            .padding(.horizontal, 16)

            Text("How often do you get paid?")
                .font(.headline)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            HStack {
                Menu {
                    Picker("Payment Frequency", selection: $paymentFrequency) {
                        ForEach(PaymentCadence.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue.capitalized)
                                .tag(frequency)
                        }
                    }
                } label: {
                    HStack {
                        Text(paymentFrequency.rawValue.capitalized)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.black)
                    }
                    .padding(12)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            }

            Spacer()

            NavigationLink(destination: CategoryQuestionView(income: .constant(income), paymentFrequency: $paymentFrequency)) {
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
}

struct PaymentInputView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentInputView()
    }
}
