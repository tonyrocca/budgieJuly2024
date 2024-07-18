import SwiftUI

struct DebtQuestionView: View {
    @State private var hasDebt = false
    @State private var selectedDebtCategories: [BudgetCategory] = []
    var paymentFrequency: PaymentCadence
    var paycheckAmountText: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Do you have any outstanding debt?")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 16)
                .padding(.horizontal, 16)

            HStack {
                Button(action: {
                    hasDebt = true
                }) {
                    Text("Yes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .shadow(radius: 5)
                }
                
                Button(action: {
                    hasDebt = false
                }) {
                    Text("No")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .shadow(radius: 5)
                }
            }

            if hasDebt {
                DebtSelectionView(selectedDebtCategories: $selectedDebtCategories)
                    .environmentObject(BudgetCategoryStore.shared)
            }

            Spacer()

            if hasDebt {
                NavigationLink(destination: DebtDetailView(selectedDebtCategories: $selectedDebtCategories, paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText).environmentObject(BudgetCategoryStore.shared)) {
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
            } else {
                NavigationLink(destination: CategorySelectionView(selectedCategories: .constant([]), paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText).environmentObject(BudgetCategoryStore.shared)) {
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
}

struct DebtQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        DebtQuestionView(paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
