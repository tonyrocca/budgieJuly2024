import SwiftUI

struct ExpenseSubcategoryAmountInputView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var selectedCategories: [BudgetCategory]
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    var hasSavingsGoals: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter expense amounts")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .foregroundColor(.primary)
                
                Text("Please enter the amount you pay for each selected expense per month.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)  // Adjusted padding to match PaymentInputView

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(selectedCategories) { category in
                        if !category.subcategories.filter({ $0.isSelected }).isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("\(category.emoji) \(category.name)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.leading, 20)
                                
                                ForEach(category.subcategories.filter { $0.isSelected }) { subcategory in
                                    HStack {
                                        Text(subcategory.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        CurrencyTextField(value: Binding(
                                            get: { subcategory.amount ?? 0 },
                                            set: { newValue in
                                                if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }),
                                                   let subIndex = budgetCategoryStore.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                                    budgetCategoryStore.categories[categoryIndex].subcategories[subIndex].amount = newValue
                                                }
                                            }))
                                            .padding(10)
                                            .background(Color(UIColor.systemGray6))
                                            .cornerRadius(8)
                                            .frame(width: 150)
                                            .multilineTextAlignment(.trailing)
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 10)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .padding(.horizontal, 10)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            
            Spacer()
            
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
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private func nextView() -> some View {
        if hasSavingsGoals {
            SavingsSelectionView(income: $income, paymentFrequency: $paymentFrequency)
                .environmentObject(budgetCategoryStore)
        } else {
            ContentView(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected }, paymentFrequency: paymentFrequency, paycheckAmountText: income)
                .environmentObject(budgetCategoryStore)
        }
    }
}

struct ExpenseSubcategoryAmountInputView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseSubcategoryAmountInputView(income: .constant("5000"), paymentFrequency: .constant(.monthly), selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected }, hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
