import SwiftUI

struct ExpenseSubcategorySelectionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    var selectedCategories: [BudgetCategory]
    var hasSavingsGoals: Bool
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
                    VStack(spacing: 0) {
                        ForEach(selectedCategories.filter { $0.type == .need }) { category in
                            VStack(spacing: 0) {
                                HStack {
                                    Text(category.emoji)
                                    Text(category.name)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
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
                                        Text("Add Subcategory")
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text("Add")
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 8)
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

                NavigationLink(destination: ExpenseSubcategoryAmountInputView(income: $income, paymentFrequency: $paymentFrequency, selectedCategories: selectedCategories, hasSavingsGoals: hasSavingsGoals)
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
                .disabled(selectedCategories.filter { $0.type == .need }.allSatisfy { $0.subcategories.filter { $0.isSelected }.isEmpty })
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))

            if showAddSubcategoryForm {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showAddSubcategoryForm = false
                    }

                VStack(spacing: 16) {
                    Text("Add New Expense Subcategory")
                        .font(.headline)
                        .padding(.top, 16)
                        .foregroundColor(.primary)

                    TextField("Name", text: $newSubcategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)

                    Button(action: addSubcategory) {
                        Text("Add")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }
                .frame(width: 300, height: 200)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.move(edge: .bottom))
            }
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
        ExpenseSubcategorySelectionView(income: .constant("5000"), paymentFrequency: .constant(.monthly), selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected }, hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
