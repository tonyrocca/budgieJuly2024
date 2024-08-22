import SwiftUI

struct SavingsQuestionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @State private var hasSavings: Bool? = nil
    var hasDebt: Bool
    var hasExpenses: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Do you have savings goals?")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .foregroundColor(.primary)
                
                Text("Select whether you have any savings goals to manage.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Yes/No Buttons
            VStack(spacing: 16) {
                Button(action: { hasSavings = true }) {
                    Text("Yes")
                        .font(.headline)
                        .foregroundColor(hasSavings == true ? .white : .primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(hasSavings == true ? Color.blue : Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }

                Button(action: { hasSavings = false }) {
                    Text("No")
                        .font(.headline)
                        .foregroundColor(hasSavings == false ? .white : .primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(hasSavings == false ? .blue : Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Next Button
            if hasSavings != nil {
                NavigationLink(
                    destination: hasSavings == true ?
                        AnyView(SavingsSelectionView(income: $income, paymentFrequency: $paymentFrequency)
                            .environmentObject(budgetCategoryStore)) :
                        AnyView(ContentView(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected }, paymentFrequency: paymentFrequency, paycheckAmountText: income, hasDebt: hasDebt, hasExpenses: hasExpenses, hasSavings: false)
                            .environmentObject(budgetCategoryStore))
                ) {
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
}
