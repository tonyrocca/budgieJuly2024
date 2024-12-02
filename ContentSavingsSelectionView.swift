import UIKit // Add this import
import SwiftUI

struct ContentSavingsSelectionView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var selectedSavings: Set<UUID> = []
    @State private var showAddSavingsForm = false
    @State private var newSavingsName = ""

    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)

    var availableSavings: [BudgetCategory] {
        budgetCategoryStore.categories.filter { $0.type == .saving && !$0.isSelected }
    }

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
                
                // Savings Goals Selection
                savingsCategorySelectionView
                
                Spacer()
                
                // Done Button
                Button(action: {
                    // Update selected categories in the store
                    let selected = budgetCategoryStore.categories.filter { selectedSavings.contains($0.id) }
                    for category in selected {
                        var newCategory = category
                        newCategory.isSelected = true
                        if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                            budgetCategoryStore.categories[index] = newCategory
                        }
                    }
                    // Dismiss the sheet
                    isPresented = false
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(customGreen)
                        .cornerRadius(10)
                        .shadow(color: customGreen.opacity(0.3), radius: 5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .disabled(selectedSavings.isEmpty)
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .padding(.top, 0)
            
            // Add Savings Modal
            if showAddSavingsForm {
                AddSavingsModal(
                    isPresented: $showAddSavingsForm,
                    newSavingsName: $newSavingsName,
                    onAdd: addSavingsCategory
                )
            }
        }
    }

    // MARK: - Savings Category Selection View
    private var savingsCategorySelectionView: some View {
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
                        ForEach(availableSavings) { saving in
                            VStack(spacing: 0) {
                                ToggleRow(
                                    isOn: Binding(
                                        get: { selectedSavings.contains(saving.id) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedSavings.insert(saving.id)
                                            } else {
                                                selectedSavings.remove(saving.id)
                                            }
                                        }
                                    ),
                                    icon: saving.emoji,
                                    text: saving.name
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .font(.body)
                                
                                if saving.id != availableSavings.last?.id {
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
    }

    // MARK: - Add Savings Category
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
        selectedSavings.insert(newCategory.id)
        showAddSavingsForm = false
        newSavingsName = ""
    }
}

// Reuse the same ToggleRow and AddSavingsModal components from before...
