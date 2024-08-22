import SwiftUI

struct ExpenseQuestionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @State private var hasExpenses: Bool? = nil
    var hasDebt: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Do you have expenses?")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .foregroundColor(.primary)
                
                Text("Select whether you have any regular expenses to manage.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Yes/No Buttons
            VStack(spacing: 16) {
                Button(action: { hasExpenses = true }) {
                    Text("Yes")
                        .font(.headline)
                        .foregroundColor(hasExpenses == true ? .white : .primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(hasExpenses == true ? Color.blue : Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }

                Button(action: { hasExpenses = false }) {
                    Text("No")
                        .font(.headline)
                        .foregroundColor(hasExpenses == false ? .white : .primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(hasExpenses == false ? .blue : Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Next Button
            if hasExpenses != nil {
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
        if hasExpenses == true {
            ExpenseSelectionView(income: $income, paymentFrequency: $paymentFrequency, hasSavingsGoals: true)
                .environmentObject(budgetCategoryStore)
        } else {
            SavingsQuestionView(income: $income, paymentFrequency: $paymentFrequency, hasDebt: hasDebt, hasExpenses: false)
                .environmentObject(budgetCategoryStore)
        }
    }
}
