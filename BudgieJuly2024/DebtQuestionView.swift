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
                NavigationLink(destination: DebtSelectionView(income: $income, paymentFrequency: $paymentFrequency, hasExpenses: true, hasSavingsGoals: true).environmentObject(budgetCategoryStore), tag: true, selection: $hasDebt) {
                    Button(action: { hasDebt = true }) {
                        Text("Yes")
                            .font(.headline)
                            .foregroundColor(hasDebt == true ? .white : .primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(hasDebt == true ? Color.blue : Color(UIColor.systemGray5))
                            .cornerRadius(10)
                    }
                }

                NavigationLink(destination: ExpenseQuestionView(income: $income, paymentFrequency: $paymentFrequency, hasDebt: false).environmentObject(budgetCategoryStore), tag: false, selection: $hasDebt) {
                    Button(action: { hasDebt = false }) {
                        Text("No")
                            .font(.headline)
                            .foregroundColor(hasDebt == false ? .white : .primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(hasDebt == false ? Color.blue : Color(UIColor.systemGray5))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(false)
        .onAppear {
            // Reset selection when the view appears
            hasDebt = nil
        }
    }
}

struct DebtQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        DebtQuestionView(income: .constant("5000"), paymentFrequency: .constant(.monthly))
            .environmentObject(BudgetCategoryStore.shared)
    }
}
