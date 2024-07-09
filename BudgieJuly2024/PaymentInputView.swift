import SwiftUI

struct PaymentInputView: View {
    @State private var paymentFrequency: PaymentCadence? = nil
    @State private var incomeText: String = ""
    @State private var showNextButton: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var selectedCategories: [BudgetCategory] = []

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Text("How often do you get paid?")
                    .font(.headline)
                    .foregroundColor(.black)

                Menu {
                    Picker("Select payment frequency", selection: Binding(
                        get: { paymentFrequency ?? .monthly },
                        set: { newValue in
                            paymentFrequency = newValue
                            updateShowNextButton()
                        }
                    )) {
                        ForEach(PaymentCadence.allCases, id: \.self) { cadence in
                            Text(cadence.rawValue).tag(PaymentCadence?.some(cadence))
                        }
                    }
                } label: {
                    HStack {
                        Text(paymentFrequency?.rawValue ?? "Select payment frequency")
                            .foregroundColor(paymentFrequency == nil ? .gray : .black)
                            .padding()
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                }

                Text("How much do you make when you get paid?")
                    .font(.headline)
                    .foregroundColor(.black)

                HStack {
                    Text("$")
                        .foregroundColor(.black)
                        .padding(.leading, 8)
                    TextField("", text: Binding(
                        get: { incomeText },
                        set: { newValue in
                            let filtered = newValue.filter { "0123456789.".contains($0) }
                            if let value = Double(filtered) {
                                incomeText = currencyFormatter.string(from: NSNumber(value: value)) ?? ""
                            } else {
                                incomeText = ""
                            }
                            updateShowNextButton()
                        }
                    ))
                    .keyboardType(.decimalPad)
                    .focused($isInputFocused)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                )
            }
            .padding(.horizontal)
            .padding(.top, 20)

            Spacer()

            if showNextButton {
                NavigationLink(destination: CategorySelectionView(selectedCategories: $selectedCategories, paymentFrequency: paymentFrequency!, paycheckAmountText: incomeText).environmentObject(BudgetCategoryStore.shared)) {
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

    private func updateShowNextButton() {
        showNextButton = paymentFrequency != nil && !incomeText.isEmpty
    }
}

struct PaymentInputView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentInputView()
            .environmentObject(BudgetCategoryStore.shared)
    }
}
