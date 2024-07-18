import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @Binding var selectedGoalCategories: [BudgetCategory]
    var paymentFrequency: PaymentCadence
    var paycheckAmountText: String

    var body: some View {
        VStack(spacing: 16) {
            headerView
            goalDetailsScrollView
            Spacer()
            nextButton
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    private var headerView: some View {
        Text("Enter your goal details")
            .font(.headline)
            .foregroundColor(.black)
            .padding(.top, 16)
            .padding(.horizontal, 16)
    }

    private var goalDetailsScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(selectedGoalCategories) { category in
                    goalDetailSection(for: category)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func goalDetailSection(for category: BudgetCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.emoji)
                    .font(.largeTitle)
                Text(category.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)

            ForEach(category.subcategories.indices, id: \.self) { subcategoryIndex in
                let subcategory = category.subcategories[subcategoryIndex]
                if subcategory.isSelected {
                    subcategoryDetailView(for: subcategory, in: category)
                }
            }
        }
        .padding(.top)
    }

    private func subcategoryDetailView(for subcategory: BudgetSubCategory, in category: BudgetCategory) -> some View {
        VStack {
            HStack {
                Text(subcategory.name)
                    .font(.body)
                Spacer()
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                amountField(for: subcategory, in: category)
                datePicker(for: subcategory, in: category)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func amountField(for subcategory: BudgetSubCategory, in category: BudgetCategory) -> some View {
        VStack(alignment: .leading) {
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.gray)
            TextField("Amount", value: Binding(
                get: { subcategory.amount ?? 0.0 },
                set: { newValue in
                    updateAmount(for: subcategory, in: category, with: newValue)
                }
            ), formatter: NumberFormatter())
            .keyboardType(.decimalPad)
            .padding()
            .background(Color(UIColor.systemGray5))
            .cornerRadius(10)
        }
    }

    private func datePicker(for subcategory: BudgetSubCategory, in category: BudgetCategory) -> some View {
        VStack(alignment: .leading) {
            Text("Target Date")
                .font(.subheadline)
                .foregroundColor(.gray)
            DatePicker("Target Date", selection: Binding(
                get: { subcategory.dueDate ?? Date() },
                set: { newValue in
                    updateDate(for: subcategory, in: category, with: newValue)
                }
            ), displayedComponents: .date)
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .background(Color(UIColor.systemGray5))
            .cornerRadius(10)
        }
    }

    private var nextButton: some View {
        NavigationLink(destination: CategorySelectionView(selectedCategories: $selectedGoalCategories, paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText).environmentObject(budgetCategoryStore)) {
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

    private func updateAmount(for subcategory: BudgetSubCategory, in category: BudgetCategory, with newValue: Double) {
        if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }),
           let subcategoryIndex = budgetCategoryStore.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
            budgetCategoryStore.categories[categoryIndex].subcategories[subcategoryIndex].amount = newValue
        }
    }

    private func updateDate(for subcategory: BudgetSubCategory, in category: BudgetCategory, with newValue: Date) {
        if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }),
           let subcategoryIndex = budgetCategoryStore.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
            budgetCategoryStore.categories[categoryIndex].subcategories[subcategoryIndex].dueDate = newValue
        }
    }
}

struct GoalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GoalDetailView(selectedGoalCategories: .constant([]), paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
