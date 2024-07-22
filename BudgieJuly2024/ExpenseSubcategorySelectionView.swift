import SwiftUI

struct ExpenseSubcategorySelectionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    var selectedCategories: [BudgetCategory]
    var hasSavingsGoals: Bool

    var body: some View {
        VStack {
            Text("Select the subcategories for your expenses.")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            List {
                ForEach(selectedCategories.filter { $0.type == .need }) { category in
                    Section(header: Text("\(category.emoji) \(category.name)")) {
                        ForEach(category.subcategories) { subcategory in
                            Toggle(isOn: Binding(
                                get: { subcategory.isSelected },
                                set: { newValue in
                                    if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                        if let subcategoryIndex = budgetCategoryStore.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                            budgetCategoryStore.categories[categoryIndex].subcategories[subcategoryIndex].isSelected = newValue
                                        }
                                    }
                                }
                            )) {
                                Text(subcategory.name)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

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
                    .padding(.horizontal)
                    .shadow(radius: 5)
            }
            .padding(.bottom, 50)
        }
        .navigationTitle("Select Subcategories")
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

struct ExpenseSubcategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseSubcategorySelectionView(income: .constant("5000"), paymentFrequency: .constant(.monthly), selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected }, hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
