import SwiftUI

struct ExpenseSelectionView: View {
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)
    
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var hasSavingsGoals: Bool
    var hasBudgetingExperience: Bool
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
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(budgetCategoryStore.categories.filter { $0.type == .need }, id: \.id) { category in
                        VStack(spacing: 0) {
                            Toggle(isOn: Binding(
                                get: { category.isSelected },
                                set: { newValue in
                                    if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                        withAnimation {
                                            budgetCategoryStore.categories[index].isSelected = newValue
                                        }
                                    }
                                }
                            )) {
                                HStack {
                                    Text(category.emoji)
                                    Text(category.name)
                                        .font(.body)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: customGreen))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            if category.id != budgetCategoryStore.categories.filter({ $0.type == .need }).last?.id {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal, 16)
            }

            Spacer()

            NavigationLink(destination: ExpenseSubcategorySelectionView(
                income: $income,
                paymentFrequency: $paymentFrequency,
                selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected },
                hasSavings: hasSavingsGoals,
                hasBudgetingExperience: hasBudgetingExperience
            ).environmentObject(budgetCategoryStore)) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(customGreen)
                    .cornerRadius(10)
                    .shadow(color: customGreen.opacity(0.3), radius: 5)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 50)
            .disabled(budgetCategoryStore.categories.filter { $0.type == .need && $0.isSelected }.isEmpty)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}
