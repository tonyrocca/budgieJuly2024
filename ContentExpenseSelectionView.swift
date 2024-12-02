import UIKit // Add this import
import SwiftUI

struct ContentExpenseSelectionView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var selectedCategories: Set<UUID> = []
    @State private var step: SelectionStep = .categories
    @State private var showAddSubcategoryForm = false
    @State private var newSubcategoryName = ""
    @State private var currentCategoryID: UUID?
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)
    
    enum SelectionStep {
        case categories
        case subcategories
    }
    
    var availableCategories: [BudgetCategory] {
        budgetCategoryStore.categories.filter { $0.type == .need && !$0.isSelected }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(step == .categories ? "Select your expenses" : "Select Subcategories")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(step == .categories ? "Choose the expenses you currently have." : "Choose the specific expenses that you want to include in your budget.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)

            // Selection Views
            if step == .categories {
                categorySelectionView
            } else {
                subcategorySelectionView
            }
            
            Spacer()
            
            // Next/Done Button
            Button(action: {
                if step == .categories {
                    if !selectedCategories.isEmpty {
                        withAnimation {
                            step = .subcategories
                        }
                    } else {
                        // Optionally, show an alert informing the user to select at least one category
                    }
                } else {
                    // Ensure at least one subcategory is selected
                    let selected = budgetCategoryStore.categories.filter { selectedCategories.contains($0.id) }
                    let hasSelectedSubcategories = selected.contains { category in
                        category.subcategories.contains { $0.isSelected }
                    }
                    
                    if hasSelectedSubcategories {
                        // Update selected categories in the store
                        for category in selected {
                            var newCategory = category
                            newCategory.isSelected = true
                            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                budgetCategoryStore.categories[index] = newCategory
                            }
                        }
                        // Dismiss the sheet
                        isPresented = false
                    } else {
                        // Optionally, show an alert informing the user to select at least one subcategory
                    }
                }
            }) {
                Text(step == .categories ? "Next" : "Done")
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
            .disabled(!canProceed)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .padding(.top, 0)
        
        // Add Subcategory Modal
        if showAddSubcategoryForm {
            AddSubcategoryModal(
                isPresented: $showAddSubcategoryForm,
                newSubcategoryName: $newSubcategoryName,
                onAdd: addSubcategory
            )
        }
    }
    
    // MARK: - Category Selection View
    private var categorySelectionView: some View {
        VStack(spacing: 0) {
            ForEach(availableCategories) { category in
                ToggleRow(
                    isOn: Binding(
                        get: { selectedCategories.contains(category.id) },
                        set: { isSelected in
                            if isSelected {
                                selectedCategories.insert(category.id)
                            } else {
                                selectedCategories.remove(category.id)
                            }
                        }
                    ),
                    icon: category.emoji,
                    text: category.name
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .font(.body)
                
                if category.id != availableCategories.last?.id {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Subcategory Selection View
    private var subcategorySelectionView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(budgetCategoryStore.categories.filter { selectedCategories.contains($0.id) }) { category in
                    VStack(spacing: 0) {
                        // Category Header with light green background
                        HStack {
                            Text(category.emoji)
                            Text(category.name)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(lightGreen)
                        
                        // Subcategories list
                        VStack(spacing: 0) {
                            ForEach(category.subcategories) { subcategory in
                                ToggleRow(
                                    isOn: Binding(
                                        get: {
                                            if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }),
                                               let subcategoryIndex = budgetCategoryStore.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                                return budgetCategoryStore.categories[categoryIndex].subcategories[subcategoryIndex].isSelected
                                            }
                                            return false
                                        },
                                        set: { newValue in
                                            if let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }),
                                               let subcategoryIndex = budgetCategoryStore.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                                budgetCategoryStore.categories[categoryIndex].subcategories[subcategoryIndex].isSelected = newValue
                                            }
                                        }
                                    ),
                                    icon: "",
                                    text: subcategory.name
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                
                                if subcategory.id != category.subcategories.last?.id {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                            
                            // Add Subcategory Button
                            Button(action: {
                                currentCategoryID = category.id
                                showAddSubcategoryForm = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(customGreen)
                                    Text("Add Subcategory")
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
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 16)
        }
    }
    
    // MARK: - Can Proceed Computed Property
    private var canProceed: Bool {
        switch step {
        case .categories:
            return !selectedCategories.isEmpty
        case .subcategories:
            let selected = budgetCategoryStore.categories.filter { selectedCategories.contains($0.id) }
            let hasSelectedSubcategories = selected.contains { category in
                category.subcategories.contains { $0.isSelected }
            }
            return hasSelectedSubcategories
        }
    }
    
    // MARK: - Add Subcategory
    private func addSubcategory() {
        let newSubcategory = BudgetSubCategory(
            name: newSubcategoryName,
            allocationPercentage: 0.0,
            description: "",
            priority: 5
        )
        if let categoryID = currentCategoryID,
           let categoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == categoryID }) {
            budgetCategoryStore.categories[categoryIndex].subcategories.append(newSubcategory)
        }
        showAddSubcategoryForm = false
        newSubcategoryName = ""
    }
}
