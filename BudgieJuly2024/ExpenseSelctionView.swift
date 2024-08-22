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
                    Toggle(isOn: Binding(
                        get: { category.isSelected },
                        set: { newValue in
                            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                budgetCategoryStore.categories[index].isSelected = newValue
                            }
                        }
                    )) {
                        HStack {
                            Text(category.emoji)
                            Text(category.name)
                                .font(.body)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    if category.id != budgetCategoryStore.categories.filter({ $0.type == .need }).last?.id {
                        Divider()
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 16)

            Spacer()

            NavigationLink(destination: ExpenseSubcategorySelectionView(income: $income, paymentFrequency: $paymentFrequency, selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected }, hasSavings: hasSavingsGoals)
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
