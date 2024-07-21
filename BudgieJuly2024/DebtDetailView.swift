import SwiftUI

struct DebtDetailView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var hasExpenses: Bool
    var hasSavingsGoals: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    var body: some View {
        VStack {
            Text("Enter your debt details")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.bottom, 10)

            Text("Please enter the amount you owe and the due date for each type of debt.")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            List {
                ForEach(budgetCategoryStore.categories.filter { $0.type == .debt && $0.isSelected }) { category in
                    VStack(alignment: .leading) {
                        Text("\(category.emoji) \(category.name)")
                            .font(.headline)
                            .padding(.bottom, 5)
                        if category.isSelected {
                            TextField("Amount", value: Binding(
                                get: { category.amount ?? 0 },
                                set: { newValue in
                                    if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                        budgetCategoryStore.categories[index].amount = newValue
                                    }
                                }), formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.bottom, 10)
                            DatePicker("Due Date", selection: Binding(
                                get: { category.dueDate ?? Date() },
                                set: { newValue in
                                    if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                        budgetCategoryStore.categories[index].dueDate = newValue
                                    }
                                }),
                                in: Date()..., // Only allow future dates
                                displayedComponents: .date
                            )
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .padding(.bottom, 10)
                            .onAppear {
                                if category.dueDate == nil {
                                    if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                        budgetCategoryStore.categories[index].dueDate = Date()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }

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
        .navigationTitle("Enter Debt Details")
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private func nextView() -> some View {
        if hasExpenses {
            ExpenseSelectionView(income: $income, paymentFrequency: $paymentFrequency, hasSavingsGoals: hasSavingsGoals)
                .environmentObject(budgetCategoryStore)
        } else if hasSavingsGoals {
            GoalSelectionView(income: $income, paymentFrequency: $paymentFrequency)
                .environmentObject(budgetCategoryStore)
        } else {
            ContentView(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected }, paymentFrequency: paymentFrequency, paycheckAmountText: income)
                .environmentObject(budgetCategoryStore)
        }
    }
}

struct DebtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DebtDetailView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasExpenses: true, hasSavingsGoals: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
