import SwiftUI

struct SavingsQuestionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @State private var hasSavings: Bool? = nil
    @State private var isInfoExpanded = false
    var hasDebt: Bool
    var hasExpenses: Bool
    var hasBudgetingExperience: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Do you have savings goals?")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                        .foregroundColor(.primary)
                    
                    Text("Select whether you have any savings goals to manage.")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)

                // Yes/No Buttons
                VStack(spacing: 16) {
                    // Navigate to SavingsSelectionView if 'Yes'
                    NavigationLink(
                        destination: SavingsSelectionView(
                            income: $income,
                            paymentFrequency: $paymentFrequency,
                            hasBudgetingExperience: hasBudgetingExperience
                        ).environmentObject(budgetCategoryStore),
                        tag: true,
                        selection: $hasSavings
                    ) {
                        Button(action: { hasSavings = true }) {
                            Text("Yes")
                                .font(.headline)
                                .foregroundColor(hasSavings == true ? .white : .primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(hasSavings == true ? Color.green : Color(UIColor.systemGray5))
                                .cornerRadius(10)
                        }
                    }

                    // Navigate to LoadingView if 'No'
                    NavigationLink(
                        destination: LoadingView(nextDestination: ContentView(
                            selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected },
                            paymentFrequency: paymentFrequency,
                            paycheckAmountText: income,
                            hasDebt: hasDebt,
                            hasExpenses: hasExpenses,
                            hasSavings: false,
                            hasBudgetingExperience: hasBudgetingExperience
                        ).environmentObject(budgetCategoryStore)),
                        tag: false,
                        selection: $hasSavings
                    ) {
                        Button(action: { hasSavings = false }) {
                            Text("No")
                                .font(.headline)
                                .foregroundColor(hasSavings == false ? .white : .primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(hasSavings == false ? Color.green : Color(UIColor.systemGray5))
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
            // Reset selection when the view appears
            hasSavings = nil
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
                    Text("What are Savings Goals?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: isInfoExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
            }

            if isInfoExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Savings goals are financial targets you set to accumulate money for future needs, wants, or emergencies.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Common types of savings goals include:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Emergency fund")
                        bulletPoint("Retirement savings")
                        bulletPoint("Down payment for a house")
                        bulletPoint("Vacation fund")
                        bulletPoint("Education expenses")
                        bulletPoint("Major purchases (e.g., car, appliances)")
                    }

                    Text("Example: If you want to save $5,000 for an emergency fund over the next 10 months, your monthly savings goal would be $500.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Setting and working towards savings goals is crucial for building financial security and achieving long-term financial objectives.")
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

struct SavingsQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        SavingsQuestionView(
            income: .constant("5000"),
            paymentFrequency: .constant(.monthly),
            hasDebt: true,
            hasExpenses: true,
            hasBudgetingExperience: true
        )
        .environmentObject(BudgetCategoryStore.shared)
    }
}
