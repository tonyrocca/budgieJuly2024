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
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .foregroundColor(.primary)
                
                Text("Choose the expenses you currently have.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, -16)  // Adjusted padding to match PaymentInputView

            List {
                ForEach(budgetCategoryStore.categories.filter { $0.type == .need }) { category in
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
                        }
                        .foregroundColor(.primary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                }
            }

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
                    .padding(.horizontal)
                    .shadow(radius: 5)
            }
            .padding(.bottom, 50)
        }
        .navigationTitle("Select Expenses")
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct ExpenseSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseSelectionView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
