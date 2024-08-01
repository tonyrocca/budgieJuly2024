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
        ZStack {
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
                    HStack {
                        HStack {
                            Text("🔧")
                            Text("Add Category")
                                .font(.body)
                        }
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showAddDebtForm = true
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
                .listStyle(InsetGroupedListStyle())

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

            if showAddDebtForm {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                VStack(spacing: 16) {
                    Text("Add New Debt Category")
                        .font(.headline)
                        .padding(.top, 16)

                    TextField("Name", text: $newDebtName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)

                    Button(action: {
                        withAnimation {
                            showAddDebtForm = false
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
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
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
