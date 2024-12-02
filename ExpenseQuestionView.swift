import SwiftUI

struct ExpenseQuestionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @State private var hasExpenses: Bool? = nil
    @State private var isInfoExpanded = false
    var hasDebt: Bool
    var hasBudgetingExperience: Bool  // Added this line
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Do you have expenses?")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                        .foregroundColor(.primary)
                
                    Text("Select whether you have any regular expenses to manage.")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)

                // Yes/No Buttons
                VStack(spacing: 16) {
                    NavigationLink(destination: ExpenseSelectionView(income: $income, paymentFrequency: $paymentFrequency, hasSavingsGoals: true, hasBudgetingExperience: hasBudgetingExperience).environmentObject(budgetCategoryStore), tag: true, selection: $hasExpenses) {
                        Button(action: { hasExpenses = true }) {
                            Text("Yes")
                                .font(.headline)
                                .foregroundColor(hasExpenses == true ? .white : .primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(hasExpenses == true ? customGreen : Color(UIColor.systemGray5))
                                .cornerRadius(10)
                        }
                    }

                    NavigationLink(destination: SavingsQuestionView(income: $income, paymentFrequency: $paymentFrequency, hasDebt: hasDebt, hasExpenses: false, hasBudgetingExperience: hasBudgetingExperience).environmentObject(budgetCategoryStore), tag: false, selection: $hasExpenses) {
                        Button(action: { hasExpenses = false }) {
                            Text("No")
                                .font(.headline)
                                .foregroundColor(hasExpenses == false ? .white : .primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(hasExpenses == false ? customGreen : Color(UIColor.systemGray5))
                                .cornerRadius(10)
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
            hasExpenses = nil
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
                    Text("What are Expenses?")
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
                    Text("Expenses are the costs you incur regularly to maintain your lifestyle and meet your basic needs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Common types of expenses include:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Housing (rent or mortgage)")
                        bulletPoint("Utilities (electricity, water, gas)")
                        bulletPoint("Food and groceries")
                        bulletPoint("Transportation")
                        bulletPoint("Insurance")
                        bulletPoint("Healthcare")
                    }

                    Text("Example: If your monthly rent is $1,000, utilities are $200, and groceries cost $400, your total basic expenses would be $1,600 per month.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Tracking and managing your expenses is crucial for maintaining a healthy budget and achieving your financial goals.")
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

struct ExpenseQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseQuestionView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasDebt: true, hasBudgetingExperience: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
