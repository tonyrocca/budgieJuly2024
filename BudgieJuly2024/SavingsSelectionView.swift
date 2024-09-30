import SwiftUI

struct SavingsSelectionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var showAddSavingsForm = false
    @State private var newSavingsName = ""
    var hasBudgetingExperience: Bool  // Added this line

    private let lightGrayColor = Color(UIColor.systemGray6)

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select your savings goals")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Choose the savings goals you want to achieve.")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)

                // Categories
                ScrollView {
                    savingsCategoryList()

                    Button(action: {
                        showAddSavingsForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add Category")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(lightGrayColor)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
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
                .disabled(selectedSavingsCategories.isEmpty)
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))

            if showAddSavingsForm {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showAddSavingsForm = false
                    }

                VStack(spacing: 20) {
                    Text("Add New Savings Goal")
                        .font(.headline)
                        .padding(.top, 20)
                        .foregroundColor(.primary)

                    TextField("Goal Name", text: $newSavingsName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: addSavingsCategory) {
                        Text("Add")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .opacity(newSavingsName.isEmpty ? 0.6 : 1.0)
                    .disabled(newSavingsName.isEmpty)
                }
                .frame(width: 300, height: 200)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle("Select Savings Goals")
    }

    private var selectedSavingsCategories: [BudgetCategory] {
        budgetCategoryStore.categories.filter { $0.isSelected && $0.type == .saving }
    }

    @ViewBuilder
    private func savingsCategoryList() -> some View {
        let savingsCategories = budgetCategoryStore.categories.filter { $0.type == .saving }
        VStack(spacing: 0) {
            ForEach(savingsCategories) { category in
                VStack(spacing: 0) {
                    ToggleRow(isOn: Binding(
                        get: { category.isSelected },
                        set: { newValue in
                            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                budgetCategoryStore.categories[index].isSelected = newValue
                            }
                        }
                    ), icon: category.emoji, text: category.name)
                    
                    if category.id != savingsCategories.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func addSavingsCategory() {
        let newCategory = BudgetCategory(
            name: newSavingsName,
            emoji: "💰",
            allocationPercentage: 0.0,
            subcategories: [],
            description: "Custom savings goal",
            type: .saving,
            isSelected: true
        )
        budgetCategoryStore.addCategory(newCategory)
        showAddSavingsForm = false
        newSavingsName = ""
    }

    @ViewBuilder
    private func nextView() -> some View {
        if hasBudgetingExperience {
            SavingsAmountInputView(
                income: $income,
                paymentFrequency: $paymentFrequency,
                selectedCategories: selectedSavingsCategories,
                hasDebt: budgetCategoryStore.categories.contains { $0.type == .debt && $0.isSelected },
                hasExpenses: budgetCategoryStore.categories.contains { $0.type == .need && $0.isSelected },
                hasBudgetingExperience: hasBudgetingExperience
            ).environmentObject(budgetCategoryStore)
        } else {
            ContentView(
                selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected },
                paymentFrequency: paymentFrequency,
                paycheckAmountText: income,
                hasDebt: budgetCategoryStore.categories.contains { $0.type == .debt && $0.isSelected },
                hasExpenses: budgetCategoryStore.categories.contains { $0.type == .need && $0.isSelected },
                hasSavings: true,
                hasBudgetingExperience: hasBudgetingExperience
            ).environmentObject(budgetCategoryStore)
        }
    }
}

struct SavingsSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SavingsSelectionView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasBudgetingExperience: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
