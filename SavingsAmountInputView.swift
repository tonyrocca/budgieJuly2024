import SwiftUI

struct SavingsAmountInputView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    var selectedCategories: [BudgetCategory]
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    var hasDebt: Bool
    var hasExpenses: Bool
    var hasBudgetingExperience: Bool

    @State private var showLoadingView = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter savings amounts")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Please enter the amount you currently save for each selected goal per month.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(selectedCategories.filter { $0.type == .saving }) { category in
                        VStack(spacing: 0) {
                            HStack {
                                Text(category.emoji)
                                Text(category.name)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(UIColor.secondarySystemBackground))

                            HStack {
                                Text(category.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack {
                                    Text("$")
                                        .foregroundColor(.primary)
                                    TextField("0", text: Binding(
                                        get: { String(format: "%.0f", category.amount ?? 0) },
                                        set: { newValue in
                                            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                                budgetCategoryStore.categories[index].amount = Double(newValue) ?? 0
                                            }
                                        }
                                    ))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                                }
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            // Button that navigates to the loading screen
            Button(action: {
                showLoadingView = true
            }) {
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
            .background(
                NavigationLink(
                    destination: LoadingView(nextDestination: ContentView(
                        selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected },
                        paymentFrequency: paymentFrequency,
                        paycheckAmountText: income,
                        hasDebt: hasDebt,
                        hasExpenses: hasExpenses,
                        hasSavings: true,
                        hasBudgetingExperience: hasBudgetingExperience
                    ).environmentObject(budgetCategoryStore)),
                    isActive: $showLoadingView
                ) {
                    EmptyView()
                }
            )
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}
