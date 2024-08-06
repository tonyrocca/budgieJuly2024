import SwiftUI

struct CategoryQuestionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @State private var hasDebt = false
    @State private var hasExpenses = false
    @State private var hasSavingsGoals = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose categories")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .foregroundColor(.primary)
                
                Text("Select yes or no on categories you want your budget to manage.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Categories
            VStack(spacing: 0) {
                ToggleRow(isOn: $hasDebt, icon: "💳", text: "Do you have debt?")
                Divider()
                ToggleRow(isOn: $hasExpenses, icon: "🏠", text: "Do you have expenses?")
                Divider()
                ToggleRow(isOn: $hasSavingsGoals, icon: "💰", text: "Do you have savings?")
            }
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 16)

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
            .disabled(!isAnyOptionSelected())
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
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

    private func isAnyOptionSelected() -> Bool {
        return hasDebt || hasExpenses || hasSavingsGoals
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
}

struct CategoryQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryQuestionView(income: .constant("5000"), paymentFrequency: .constant(.monthly))
            .environmentObject(BudgetCategoryStore.shared)
    }
}
