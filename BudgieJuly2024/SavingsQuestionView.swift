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
                NavigationLink(destination: SavingsSelectionView(income: $income, paymentFrequency: $paymentFrequency).environmentObject(budgetCategoryStore), tag: true, selection: $hasSavings) {
                    Button(action: { hasSavings = true }) {
                        Text("Yes")
                            .font(.headline)
                            .foregroundColor(hasSavings == true ? .white : .primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(hasSavings == true ? Color.blue : Color(UIColor.systemGray5))
                            .cornerRadius(10)
                    }
                }

                NavigationLink(destination: ContentView(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected }, paymentFrequency: paymentFrequency, paycheckAmountText: income, hasDebt: hasDebt, hasExpenses: hasExpenses, hasSavings: false).environmentObject(budgetCategoryStore), tag: false, selection: $hasSavings) {
                    Button(action: { hasSavings = false }) {
                        Text("No")
                            .font(.headline)
                            .foregroundColor(hasSavings == false ? .white : .primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(hasSavings == false ? Color.blue : Color(UIColor.systemGray5))
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
            hasSavings = nil
        }
    }
}
