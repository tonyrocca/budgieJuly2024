import SwiftUI

struct ExpenseSelectionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var hasSavingsGoals: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Select your expenses")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Choose the expenses you currently have.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)

            // Expenses
            VStack(spacing: 0) {
                ForEach(budgetCategoryStore.categories.filter { $0.type == .need }, id: \.id) { category in
                    ToggleRow(isOn: Binding(
                        get: { category.isSelected },
                        set: { newValue in
                            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                budgetCategoryStore.categories[index].isSelected = newValue
                            }
                        }
                    ), icon: category.emoji, text: category.name)
                    
                    if category.id != budgetCategoryStore.categories.filter({ $0.type == .need }).last?.id {
                        Divider()
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 16)

            Spacer()

            NavigationLink(destination: ExpenseSubcategorySelectionView(income: $income, paymentFrequency: $paymentFrequency, selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected }, hasSavingsGoals: hasSavingsGoals)
                .environmentObject(budgetCategoryStore)) {
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
            .disabled(budgetCategoryStore.categories.filter { $0.type == .need && $0.isSelected }.isEmpty)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct ExpenseSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseSelectionView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
