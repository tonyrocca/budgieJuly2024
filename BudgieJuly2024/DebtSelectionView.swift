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

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Select your debt categories")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .foregroundColor(.primary)

                Text("Choose the debt you currently are paying off.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Categories
            VStack(spacing: 0) {
                ForEach(budgetCategoryStore.categories.filter { $0.type == .debt }) { category in
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
                Button(action: {
                    withAnimation {
                        showAddDebtForm = true
                    }
                }) {
                    HStack {
                        Text("🔧")
                        Text("Add Category")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Add")
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 16)

            Spacer()

            NavigationLink(destination: DebtDetailView(income: $income, paymentFrequency: $paymentFrequency, hasExpenses: hasExpenses, hasSavingsGoals: hasSavingsGoals)
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
            .disabled(selectedDebtCategories.isEmpty)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showAddDebtForm) {
            AddDebtCategoryView(isPresented: $showAddDebtForm, newDebtName: $newDebtName, budgetCategoryStore: budgetCategoryStore, selectedDebtCategories: $selectedDebtCategories)
        }
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

struct AddDebtCategoryView: View {
    @Binding var isPresented: Bool
    @Binding var newDebtName: String
    var budgetCategoryStore: BudgetCategoryStore
    @Binding var selectedDebtCategories: [UUID]

    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Debt Category")
                .font(.headline)
                .padding(.top, 16)
                .foregroundColor(.primary)

            TextField("Name", text: $newDebtName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            Button(action: {
                withAnimation {
                    isPresented = false
                }
                let newCategory = BudgetCategory(
                    name: newDebtName,
                    emoji: "💳",
                    allocationPercentage: 0.0,
                    subcategories: [],
                    description: "Custom debt",
                    type: .debt,
                    isSelected: true
                )
                budgetCategoryStore.addCategory(newCategory)
                selectedDebtCategories.append(newCategory.id)
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
    }
}

struct DebtSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DebtSelectionView(
            income: .constant("5000"),
            paymentFrequency: .constant(.monthly),
            hasExpenses: true,
            hasSavingsGoals: true
        )
        .environmentObject(BudgetCategoryStore.shared)
    }
}
