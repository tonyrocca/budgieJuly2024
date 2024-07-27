import SwiftUI

struct CategoryQuestionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @State private var hasDebt = false
    @State private var hasExpenses = false
    @State private var hasSavingsGoals = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Select each component that you want in your budget.")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .multilineTextAlignment(.center)

            List {
                Toggle(isOn: $hasDebt) {
                    HStack {
                        Text("💳")
                        Text("Debt")
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                .onChange(of: hasDebt) { _ in updateNextButtonVisibility() }

                Toggle(isOn: $hasExpenses) {
                    HStack {
                        Text("🏠")
                        Text("Expenses")
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                .onChange(of: hasExpenses) { _ in updateNextButtonVisibility() }

                Toggle(isOn: $hasSavingsGoals) {
                    HStack {
                        Text("💰")
                        Text("Savings")
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                .onChange(of: hasSavingsGoals) { _ in updateNextButtonVisibility() }
            }
            .listStyle(InsetGroupedListStyle())
            .frame(height: 200)

            Spacer()

            if hasDebt || hasExpenses || hasSavingsGoals {
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
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private func nextView() -> some View {
        if hasDebt {
            DebtSelectionView(income: $income, paymentFrequency: $paymentFrequency, hasExpenses: hasExpenses, hasSavingsGoals: hasSavingsGoals)
                .environmentObject(BudgetCategoryStore.shared)
        } else if hasExpenses {
            ExpenseSelectionView(income: $income, paymentFrequency: $paymentFrequency, hasSavingsGoals: hasSavingsGoals)
                .environmentObject(BudgetCategoryStore.shared)
        } else if hasSavingsGoals {
            SavingsSelectionView(income: $income, paymentFrequency: $paymentFrequency)
                .environmentObject(BudgetCategoryStore.shared)
        } else {
            ContentView(selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected }, paymentFrequency: paymentFrequency, paycheckAmountText: income)
                .environmentObject(BudgetCategoryStore.shared)
        }
    }

    private func updateNextButtonVisibility() {
        // This method is a placeholder to trigger a state update when toggles are changed.
    }
}

struct CategoryQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryQuestionView(income: .constant("5000"), paymentFrequency: .constant(.monthly))
            .environmentObject(BudgetCategoryStore.shared)
    }
}
