import SwiftUI

struct DebtSelectionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var showAddDebtForm = false
    @State private var newDebtName = ""
    @State private var selectedDebtCategories: [UUID] = []

    var hasExpenses: Bool
    var hasSavingsGoals: Bool

    var body: some View {
        VStack {
            Text("Select your debt categories.")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            List {
                ForEach(budgetCategoryStore.categories.filter { $0.type == .debt }) { category in
                    Toggle(isOn: Binding(
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
                    )) {
                        HStack {
                            Text(category.emoji)
                            Text(category.name)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            Button(action: {
                showAddDebtForm = true
            }) {
                Text("Add Debt Category")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

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
                    .padding(.horizontal)
                    .shadow(radius: 5)
            }
            .padding(.bottom, 50)
        }
        .navigationTitle("Select Debts")
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showAddDebtForm) {
            VStack {
                Text("Add New Debt Category")
                    .font(.title2)
                    .bold()
                    .padding()

                TextField("Name", text: $newDebtName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
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
                    showAddDebtForm = false
                }) {
                    Text("Add")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()

                Spacer()
            }
            .padding()
        }
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
