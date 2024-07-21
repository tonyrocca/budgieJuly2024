import SwiftUI

struct PaymentInputView: View {
    @State private var income: String = ""
    @State private var paymentFrequency: PaymentCadence = .monthly

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter your income and payment frequency")
                .font(.headline)
                .padding(.top, 16)

            TextField("Income", text: $income)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 16)

            Picker("Payment Frequency", selection: $paymentFrequency) {
                ForEach(PaymentCadence.allCases, id: \.self) { frequency in
                    Text(frequency.rawValue.capitalized).tag(frequency)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)

            Spacer()

            NavigationLink(destination: CategoryQuestionView(income: $income, paymentFrequency: $paymentFrequency)) {
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
}

struct PaymentInputView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentInputView()
    }
}
