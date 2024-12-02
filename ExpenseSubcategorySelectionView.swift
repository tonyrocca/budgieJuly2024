import SwiftUI

struct ExpenseSubcategorySelectionView: View {
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)
    
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    var selectedCategories: [BudgetCategory]
    var hasSavings: Bool
    var hasBudgetingExperience: Bool
    @State private var showAddSubcategoryForm = false
    @State private var newSubcategoryName = ""
    @State private var currentCategoryID: UUID?

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select subcategories")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Choose the specific expenses that you want to include in your budget.")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)

                // Subcategories
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(selectedCategories.filter { $0.type == .need }) { category in
                            VStack(spacing: 0) {
                                // Category Header with light green background
                                HStack {
                                    Text(category.emoji)
                                    Text(category.name)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(lightGreen)

                                // Subcategories list
                                VStack(spacing: 0) {
                                    ForEach(category.subcategories) { subcategory in
                                        ToggleRow(isOn: Binding(
                                            get: { subcategory.isSelected },
                                            set: { newValue in
                                                if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }),
                                                   let subcategoryIndex = budgetCategoryStore.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                                    budgetCategoryStore.categories[categoryIndex].subcategories[subcategoryIndex].isSelected = newValue
                                                }
                                            }
                                        ), icon: "", text: subcategory.name)
                                        
                                        if subcategory.id != category.subcategories.last?.id {
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }

                                    // Add Subcategory Button
                                    Button(action: {
                                        currentCategoryID = category.id
                                        showAddSubcategoryForm = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(customGreen)
                                            Text("Add Subcategory")
                                                .foregroundColor(customGreen)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(8)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()

                // Next Button
                NavigationLink(destination: nextView()) {
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
                .disabled(selectedCategories.filter { $0.type == .need }.allSatisfy { $0.subcategories.filter { $0.isSelected }.isEmpty })
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))

            if showAddSubcategoryForm {
                AddSubcategoryModal(
                    isPresented: $showAddSubcategoryForm,
                    newSubcategoryName: $newSubcategoryName,
                    onAdd: addSubcategory
                )
            }
        }
    }

    @ViewBuilder
    private func nextView() -> some View {
        if hasBudgetingExperience {
            ExpenseSubcategoryAmountInputView(
                income: $income,
                paymentFrequency: $paymentFrequency,
                selectedCategories: selectedCategories,
                hasSavingsGoals: hasSavings,
                hasBudgetingExperience: hasBudgetingExperience
            )
            .environmentObject(budgetCategoryStore)
        } else {
            SavingsQuestionView(
                income: $income,
                paymentFrequency: $paymentFrequency,
                hasDebt: selectedCategories.contains(where: { $0.type == .debt }),
                hasExpenses: true,
                hasBudgetingExperience: hasBudgetingExperience
            )
            .environmentObject(budgetCategoryStore)
        }
    }

    private func addSubcategory() {
        let newSubcategory = BudgetSubCategory(
            name: newSubcategoryName,
            allocationPercentage: 0.0,
            description: "",
            priority: 5  // Default to lowest priority
        )
        if let categoryID = currentCategoryID,
           let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == categoryID }) {
            budgetCategoryStore.categories[categoryIndex].subcategories.append(newSubcategory)
        }
        showAddSubcategoryForm = false
        newSubcategoryName = ""
    }
}

struct ExpenseSubcategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseSubcategorySelectionView(
            income: .constant("5000"),
            paymentFrequency: .constant(.monthly),
            selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected },
            hasSavings: true,
            hasBudgetingExperience: true  // Added this line to the preview
        )
        .environmentObject(BudgetCategoryStore.shared)
    }
}
