import SwiftUI

struct DebtQuestionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @State private var hasDebt: Bool? = nil
    @State private var isInfoExpanded = false
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    var hasBudgetingExperience: Bool  // Added this line

    // Add the custom green color definition
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Do you have debt?")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                        .foregroundColor(.primary)

                    Text("Select whether you have any outstanding debts to manage.")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)

                // Yes/No Buttons - Updated with custom green
                VStack(spacing: 16) {
                    NavigationLink(
                        destination: DebtSelectionView(income: $income, paymentFrequency: $paymentFrequency, hasExpenses: true, hasSavingsGoals: true, hasBudgetingExperience: hasBudgetingExperience).environmentObject(budgetCategoryStore),
                        tag: true,
                        selection: $hasDebt
                    ) {
                        Button(action: { hasDebt = true }) {
                            Text("Yes")
                                .font(.headline)
                                .foregroundColor(hasDebt == true ? .white : .primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(hasDebt == true ? customGreen : Color(UIColor.systemGray5))
                                .cornerRadius(10)
                                .shadow(color: hasDebt == true ? customGreen.opacity(0.3) : Color.clear, radius: 5)
                        }
                    }

                    NavigationLink(
                        destination: ExpenseQuestionView(income: $income, paymentFrequency: $paymentFrequency, hasDebt: false, hasBudgetingExperience: hasBudgetingExperience).environmentObject(budgetCategoryStore),
                        tag: false,
                        selection: $hasDebt
                    ) {
                        Button(action: { hasDebt = false }) {
                            Text("No")
                                .font(.headline)
                                .foregroundColor(hasDebt == false ? .white : .primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(hasDebt == false ? customGreen : Color(UIColor.systemGray5))
                                .cornerRadius(10)
                                .shadow(color: hasDebt == false ? customGreen.opacity(0.3) : Color.clear, radius: 5)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Information Dropdown
                infoDropdown

                Spacer()
            }
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(false)
        .onAppear {
            hasDebt = nil
        }
    }

    private var infoDropdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isInfoExpanded.toggle()
                }
            }) {
                HStack {
                    Text("What is Debt?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: isInfoExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)

            if isInfoExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Debt refers to money that you owe to others. It's a financial obligation that you're expected to repay, often with interest.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Common types of debt include:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Credit card balances")
                        bulletPoint("Student loans")
                        bulletPoint("Mortgages")
                        bulletPoint("Personal loans")
                        bulletPoint("Car loans")
                    }

                    Text("Example: If you have a credit card balance of $1,000 and a student loan of $20,000, your total debt would be $21,000.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Managing your debt is crucial for financial health. It affects your credit score, borrowing capacity, and ability to achieve other financial goals.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .transition(.opacity)
            }
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct DebtQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        DebtQuestionView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasBudgetingExperience: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
