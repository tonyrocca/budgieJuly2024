import SwiftUI

struct SavingsSelectionView: View {
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)
    
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var showAddSavingsForm = false
    @State private var newSavingsName = ""
    var hasBudgetingExperience: Bool
    
    var body: some View {
        ZStack {  // Wrap everything in a ZStack to properly layer the modal
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
                .padding(.horizontal, 16)
                
                // Categories
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 0) {
                            // Section Header
                            HStack {
                                Text("💰")
                                Text("Your Savings Goals")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(lightGreen)
                            
                            // Savings Categories List
                            VStack(spacing: 0) {
                                ForEach(budgetCategoryStore.categories.filter { $0.type == .saving }, id: \.id) { category in
                                    VStack(spacing: 0) {
                                        ToggleRow(
                                            isOn: Binding(
                                                get: { category.isSelected },
                                                set: { newValue in
                                                    if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                                        budgetCategoryStore.categories[index].isSelected = newValue
                                                    }
                                                }
                                            ),
                                            icon: category.emoji,
                                            text: category.name
                                        )
                                        
                                        if category.id != budgetCategoryStore.categories.filter({ $0.type == .saving }).last?.id {
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                
                                // Add Category Button
                                Button(action: { showAddSavingsForm = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(customGreen)
                                        Text("Add Goal")
                                            .foregroundColor(customGreen)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                NavigationLink(destination: nextView()) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(customGreen)
                        .cornerRadius(10)
                        .shadow(color: customGreen.opacity(0.3), radius: 5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 50)
                .disabled(selectedSavingsCategories.isEmpty)
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            
            if showAddSavingsForm {
                AddSavingsModal(
                    isPresented: $showAddSavingsForm,
                    newSavingsName: $newSavingsName,
                    onAdd: addSavingsCategory
                )
            }
        }
    }
    
    private var selectedSavingsCategories: [BudgetCategory] {
        budgetCategoryStore.categories.filter { $0.isSelected && $0.type == .saving }
    }
    
    private func addSavingsCategory() {
        let newCategory = BudgetCategory(
            name: newSavingsName,
            emoji: "💰",
            allocationPercentage: 0.0,
            subcategories: [],
            description: "Custom savings goal",
            type: .saving,
            isSelected: true,
            priority: 5
        )
        budgetCategoryStore.addCategory(
            name: newSavingsName,
            emoji: "💰",
            allocationPercentage: 0.0,
            subcategories: [],
            description: "Custom savings goal",
            type: .saving,
            isSelected: true,
            priority: 5
        )
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
            LoadingView(nextDestination: ContentView(
                selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected },
                paymentFrequency: paymentFrequency,
                paycheckAmountText: income,
                hasDebt: budgetCategoryStore.categories.contains { $0.type == .debt && $0.isSelected },
                hasExpenses: budgetCategoryStore.categories.contains { $0.type == .need && $0.isSelected },
                hasSavings: true,
                hasBudgetingExperience: hasBudgetingExperience
            ).environmentObject(budgetCategoryStore))
        }
    }
}

// Reuse the same ToggleRow and AddSavingsModal components from before...

struct AddSavingsModal: View {
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    @Binding var isPresented: Bool
    @Binding var newSavingsName: String
    let onAdd: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            // Modal content
            VStack(spacing: 24) {
                // Header with close button
                HStack {
                    Text("Add New Savings Goal")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                
                // Icon and description
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(customGreen)
                    
                    Text("Enter the name of your savings goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Text field
                TextField("Savings Goal Name", text: $newSavingsName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                
                // Add button
                Button(action: {
                    onAdd()
                    isPresented = false
                }) {
                    Text("Add Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(customGreen)
                        .cornerRadius(10)
                }
                .disabled(newSavingsName.isEmpty)
                .opacity(newSavingsName.isEmpty ? 0.6 : 1.0)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10)
            .padding(.horizontal, 40)
        }
    }
}

struct SavingsSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SavingsSelectionView(income: .constant("5000"), paymentFrequency: .constant(.monthly), hasBudgetingExperience: true)
            .environmentObject(BudgetCategoryStore.shared)
    }
}
