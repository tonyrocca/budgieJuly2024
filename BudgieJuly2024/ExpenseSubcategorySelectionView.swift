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
                    
                    Text("Choose the specific categories for your expenses.")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .padding(.bottom, -16) // Adjusted padding to match PaymentInputView

                List {
                    ForEach(selectedCategories.filter { $0.type == .need }) { category in
                        Section(header: Text("\(category.emoji) \(category.name.capitalized)").font(.headline).foregroundColor(.primary)) {
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
                                .toggleStyle(SwitchToggleStyle(tint: .blue)) // Change toggle color to blue
                            }
                            
                            HStack {
                                Text("Add Subcategory")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        currentCategoryID = category.id
                                        showAddSubcategoryForm = true
                                    }
                                }) {
                                    Text("Add")
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 30)  // Adjust to match the dimensions of the toggle button
                                        .background(Color.blue)
                                        .cornerRadius(15)  // Adjust to match the style of the toggle button
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .frame(maxWidth: .infinity) // Ensure the frame takes the full width
                .padding(.horizontal, 16)

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
                        .padding(.horizontal)
                        .shadow(radius: 5)
                }
                .padding(.bottom, 50)
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))

            if showAddSubcategoryForm {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
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

                    Button(action: {
                        withAnimation {
                            showAddSubcategoryForm = false
                        }
                        let newSubcategory = BudgetSubCategory(name: newSubcategoryName, allocationPercentage: 0.0, description: "")
                        if let categoryID = currentCategoryID {
                            budgetCategoryStore.addSubcategoryToCategory(newSubcategory, categoryID: categoryID)
                        }
                    }) {
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
                .zIndex(1)
            }
        }
    }
}

struct ExpenseSubcategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseSubcategorySelectionView(income: .constant("5000"), paymentFrequency: .constant(.monthly), selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected }, hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
