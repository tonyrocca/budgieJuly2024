import SwiftUI

struct DebtSelectionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var selectedDebtCategories: [UUID] = []
    @State private var showAddDebtForm = false
    @State private var newDebtName = ""
    
    var hasExpenses: Bool
    var hasSavingsGoals: Bool
    var hasBudgetingExperience: Bool  // Added this line

    private let lightGrayColor = Color(UIColor.systemGray6)

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select your debt categories")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Choose the debt you currently are paying off.")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

                // Categories
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(budgetCategoryStore.categories.filter { $0.type == .debt }, id: \.id) { category in
                            ToggleRow(isOn: Binding(
                                get: { selectedDebtCategories.contains(category.id) },
                                set: { newValue in
                                    if newValue {
                                        selectedDebtCategories.append(category.id)
                                        if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                            budgetCategoryStore.categories[index].isSelected = true
                                        }
                                    } else {
                                        if let index = selectedDebtCategories.firstIndex(of: category.id) {
                                            selectedDebtCategories.remove(at: index)
                                            if let catIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                                budgetCategoryStore.categories[catIndex].isSelected = false
                                            }
                                        }
                                    }
                                }
                            ), icon: category.emoji, text: category.name)

                            if category.id != budgetCategoryStore.categories.filter({ $0.type == .debt }).last?.id {
                                Divider()
                            }
                        }
                    }

                    Button(action: {
                        showAddDebtForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add Category")
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
                .padding(.horizontal, 16)

                Spacer()

                NavigationLink(destination: DebtDetailView(
                    income: $income,
                    paymentFrequency: $paymentFrequency,
                    hasExpenses: hasExpenses,
                    hasSavings: hasSavingsGoals,
                    hasBudgetingExperience: hasBudgetingExperience  // Passing the new parameter
                ).environmentObject(budgetCategoryStore)) {
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
                .disabled(selectedDebtCategories.isEmpty)
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))

            if showAddDebtForm {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showAddDebtForm = false
                    }

                VStack(spacing: 20) {
                    Text("Add New Debt Category")
                        .font(.headline)
                        .padding(.top, 20)
                        .foregroundColor(.primary)

                    TextField("Category Name", text: $newDebtName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: addDebtCategory) {
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
                    .opacity(newDebtName.isEmpty ? 0.6 : 1.0)
                    .disabled(newDebtName.isEmpty)
                }
                .frame(width: 300, height: 200)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle("Select Debt Categories")
    }

    private func addDebtCategory() {
        let newCategory = BudgetCategory(
            name: newDebtName,
            emoji: "💳",
            allocationPercentage: 0.0,
            subcategories: [],
            description: "Custom debt category",
            type: .debt,
            isSelected: true,
            priority: 5  // Default to lowest priority
        )
        budgetCategoryStore.addCategory(
            name: newDebtName,
            emoji: "💳",
            allocationPercentage: 0.0,
            subcategories: [],
            description: "Custom debt category",
            type: .debt,
            isSelected: true,
            priority: 5  // Default to lowest priority
        )
        selectedDebtCategories.append(newCategory.id)
        showAddDebtForm = false
        newDebtName = ""
    }
}

struct ToggleRow: View {
    @Binding var isOn: Bool
    let icon: String
    let text: String

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Text(icon)
                Text(text)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.blue))
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct DebtSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DebtSelectionView(
            income: .constant("5000"),
            paymentFrequency: .constant(.monthly),
            hasExpenses: true,
            hasSavingsGoals: true,
            hasBudgetingExperience: true  // Added this line to the preview
        )
        .environmentObject(BudgetCategoryStore.shared)
    }
}

struct DebtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DebtDetailView(
            income: .constant("5000"),
            paymentFrequency: .constant(.monthly),
            hasExpenses: true,
            hasSavings: true,
            hasBudgetingExperience: true  // Added this line to the preview
        )
        .environmentObject(BudgetCategoryStore.shared)
    }
}
