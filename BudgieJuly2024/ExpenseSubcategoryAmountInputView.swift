import SwiftUI

struct ExpenseSubcategoryAmountInputView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var selectedCategories: [BudgetCategory]
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    var body: some View {
        VStack {
            Text("Enter your expense amounts")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 30)
                .foregroundColor(.primary)
            
            Text("Please enter the amount you pay for each selected subcategory per month.")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal, 30)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
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
                                            .multilineTextAlignment(.trailing) // Ensure right alignment
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 10)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            
            Spacer()
            
            NavigationLink(destination: ContentView(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected }, paymentFrequency: paymentFrequency, paycheckAmountText: income)
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
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 50)
        }
        .navigationTitle("Enter Expense Amounts")
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct ExpenseSubcategoryAmountInputView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseSubcategoryAmountInputView(income: .constant("5000"), paymentFrequency: .constant(.monthly), selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected })
            .environmentObject(BudgetCategoryStore.shared)
    }
}
