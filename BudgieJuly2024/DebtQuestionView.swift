import SwiftUI

struct DebtQuestionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @State private var hasDebt: Bool? = nil
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Do you have debt?")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .foregroundColor(.primary)
                
                Text("Select whether you have any outstanding debts to manage.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Yes/No Buttons
            VStack(spacing: 16) {
                Button(action: { hasDebt = true }) {
                    Text("Yes")
                        .font(.headline)
                        .foregroundColor(hasDebt == true ? .white : .primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(hasDebt == true ? Color.blue : Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }

                Button(action: { hasDebt = false }) {
                    Text("No")
                        .font(.headline)
                        .foregroundColor(hasDebt == false ? .white : .primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(hasDebt == false ? .blue : Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Next Button
            if hasDebt != nil {
                NavigationLink(destination: nextView().environmentObject(budgetCategoryStore)) {
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
            }
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private func nextView() -> some View {
        if hasDebt == true {
            DebtSelectionView(income: $income, paymentFrequency: $paymentFrequency, hasExpenses: true, hasSavingsGoals: true)
                .environmentObject(budgetCategoryStore)
        } else {
            ExpenseQuestionView(income: $income, paymentFrequency: $paymentFrequency, hasDebt: false)
                .environmentObject(budgetCategoryStore)
        }
    }
}

struct DebtQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        DebtQuestionView(income: .constant("5000"), paymentFrequency: .constant(.monthly))
            .environmentObject(BudgetCategoryStore.shared)
    }
}
