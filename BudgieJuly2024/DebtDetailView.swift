import SwiftUI

struct DebtDetailView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @Binding var selectedDebtCategories: [BudgetCategory]
    var paymentFrequency: PaymentCadence
    var paycheckAmountText: String

    @State private var expandedCategory: UUID?

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter your debt details")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 16)
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(selectedDebtCategories) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(category.emoji)
                                    .font(.largeTitle)
                                Text(category.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        if expandedCategory == category.id {
                                            expandedCategory = nil
                                        } else {
                                            expandedCategory = category.id
                                        }
                                    }
                                }) {
                                    Image(systemName: expandedCategory == category.id ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)

                            if expandedCategory == category.id {
                                VStack(alignment: .leading, spacing: 8) {
                                    amountField(for: category)
                                    datePicker(for: category)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                            }
                        }
                        .padding(.top)
                        Divider()
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            NavigationLink(destination: CategorySelectionView(selectedCategories: .constant([]), paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText).environmentObject(budgetCategoryStore)) {
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
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    private func amountField(for category: BudgetCategory) -> some View {
        VStack(alignment: .leading) {
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.gray)
            TextField("Amount", value: Binding(
                get: { category.amount ?? 0.0 },
                set: { newValue in
                    updateAmount(for: category, with: newValue)
                }
            ), formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .padding()
            .background(Color(UIColor.systemGray5))
            .cornerRadius(10)
        }
    }

    private func datePicker(for category: BudgetCategory) -> some View {
        VStack(alignment: .leading) {
            Text("Due Date")
                .font(.subheadline)
                .foregroundColor(.gray)
            DatePicker("Due Date", selection: Binding(
                get: { category.dueDate ?? Date() },
                set: { newValue in
                    updateDate(for: category, with: newValue)
                }
            ), displayedComponents: .date)
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .background(Color(UIColor.systemGray5))
            .cornerRadius(10)
        }
    }

    private func updateAmount(for category: BudgetCategory, with newValue: Double) {
        if let categoryIndex = selectedDebtCategories.firstIndex(where: { $0.id == category.id }) {
            selectedDebtCategories[categoryIndex].amount = newValue
            if let storeCategoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                budgetCategoryStore.categories[storeCategoryIndex].amount = newValue
            }
        }
    }

    private func updateDate(for category: BudgetCategory, with newValue: Date) {
        if let categoryIndex = selectedDebtCategories.firstIndex(where: { $0.id == category.id }) {
            selectedDebtCategories[categoryIndex].dueDate = newValue
            if let storeCategoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                budgetCategoryStore.categories[storeCategoryIndex].dueDate = newValue
            }
        }
    }
}

struct DebtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DebtDetailView(selectedDebtCategories: .constant([]), paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
