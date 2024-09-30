import SwiftUI

struct ExpenseSubcategorySelectionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    var selectedCategories: [BudgetCategory]
    var hasSavings: Bool
    var hasBudgetingExperience: Bool  // Added this line
    @State private var showAddSubcategoryForm = false
    @State private var newSubcategoryName = ""
    @State private var currentCategoryID: UUID?

    private let lightGrayColor = Color(UIColor.systemGray6)

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
                                HStack {
                                    Text(category.emoji)
                                    Text(category.name)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color(UIColor.secondarySystemBackground))

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
                                    }
                                }

                                Button(action: {
                                    currentCategoryID = category.id
                                    showAddSubcategoryForm = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("Add Subcategory")
                                            .foregroundColor(.blue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(lightGrayColor)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
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
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 50)
                .disabled(selectedCategories.filter { $0.type == .need }.allSatisfy { $0.subcategories.filter { $0.isSelected }.isEmpty })
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))

            if showAddSubcategoryForm {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showAddSubcategoryForm = false
                    }

                VStack(spacing: 20) {
                    Text("Add New Expense Subcategory")
                        .font(.headline)
                        .padding(.top, 20)
                        .foregroundColor(.primary)

                    TextField("Subcategory Name", text: $newSubcategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: addSubcategory) {
                        Text("Add")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .opacity(newSubcategoryName.isEmpty ? 0.6 : 1.0)
                    .disabled(newSubcategoryName.isEmpty)
                }
                .frame(width: 300, height: 200)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.move(edge: .bottom))
            }
        }
    }

    // New nextView function based on hasBudgetingExperience
    @ViewBuilder
    private func nextView() -> some View {
        if hasBudgetingExperience {
            ExpenseSubcategoryAmountInputView(
                income: $income,
                paymentFrequency: $paymentFrequency,
                selectedCategories: selectedCategories,
                hasSavingsGoals: hasSavings,
                hasBudgetingExperience: hasBudgetingExperience  // Passing the new parameter
            )
            .environmentObject(budgetCategoryStore)
        } else {
            SavingsQuestionView(
                income: $income,
                paymentFrequency: $paymentFrequency,
                hasDebt: selectedCategories.contains(where: { $0.type == .debt }),
                hasExpenses: true,
                hasBudgetingExperience: hasBudgetingExperience  // Passing the new parameter
            )
            .environmentObject(budgetCategoryStore)
        }
    }

    private func addSubcategory() {
        let newSubcategory = BudgetSubCategory(name: newSubcategoryName, allocationPercentage: 0.0, description: "")
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
