import UIKit // Add this import

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                              byRoundingCorners: corners,
                              cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

import SwiftUI

private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)

// MARK: - SectionHeaderView
struct SectionHeaderView: View {
    let title: String
    let color: Color
    let infoText: String
    let type: CategoryType
    let onAddTap: () -> Void
    @State private var showingInfo = false
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Title and Info
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: { showingInfo.toggle() }) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Add button
                Button(action: onAddTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                        Text("Add")
                            .font(.subheadline)
                    }
                    .foregroundColor(customGreen)
                    .padding(.trailing, 16)
                }
            }
            .background(lightGreen)
            .cornerRadius(10, corners: [.topLeft, .topRight])
            .overlay(
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .alert("Information", isPresented: $showingInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(infoText)
        }
    }
}

struct InfoButton: View {
    let text: String
    @State private var showingInfo = false

    var body: some View {
        Button(action: { showingInfo.toggle() }) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue.opacity(0.7))
                .font(.system(size: 14))
        }
        .alert("Information", isPresented: $showingInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(text)
        }
    }
}

// Add this enum to track the view period
enum ViewPeriod: String, CaseIterable {
    case perPaycheck = "Per Paycheck"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var suffix: String {
        switch self {
        case .perPaycheck: return "/paycheck"
        case .monthly: return "/mo"
        case .yearly: return "/yr"
        }
    }
}

struct CategorySelectionModal: View {
    @Binding var isPresented: Bool
    let type: CategoryType
    let onSelect: ([BudgetCategory]) -> Void
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var selectedCategories: Set<UUID> = []
    @State private var step: SelectionStep = .categories
    @State private var debtAmounts: [UUID: String] = [:]
    @State private var selectedDates: [UUID: Date] = [:]
    @State private var showDatePicker: UUID? = nil
    @State private var showAddSubcategoryForm = false
    @State private var newSubcategoryName = ""
    @State private var currentCategoryID: UUID?
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.05)
    
    enum SelectionStep {
        case categories
        case subcategories
        case debtDetails
    }
    
    var availableCategories: [BudgetCategory] {
        budgetCategoryStore.categories.filter { $0.type == type && !$0.isSelected }
    }
    
    var body: some View {
        if type == .need {
            expenseSelectionView
        } else if type == .saving || type == .debt {
            specializedSelectionView
        } else {
            defaultCategoryView
        }
    }
    
    private var expenseSelectionView: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Green Header
                    ZStack {
                        // Gray Header (replaces the green header)
                        ZStack {
                            Rectangle()
                                .fill(Color(UIColor.systemGray6))  // Light gray background
                                .frame(height: 80)  // Reduced height
                                .edgesIgnoringSafeArea(.top)
                            
                            VStack {
                                Text(step == .categories ? "Add Expense" : "Select Subcategories")
                                    .font(.system(size: 28, weight: .bold))  // Smaller font
                                    .foregroundColor(.black)  // Black text
                                    .padding(.top, 45)
                            }
                        }
                    }
                    
                    // Subtitle text
                    Text(step == .categories ?
                         "Choose the expenses you currently have." :
                         "Choose the specific expenses that you want to include in your budget.")
                    .font(.system(size: 22))
                    .foregroundColor(.black)  // Changed from gray to black
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if step == .categories {
                        ScrollView {
                            VStack(spacing: 1) {
                                ForEach(availableCategories) { category in
                                    Toggle(isOn: Binding(
                                        get: { selectedCategories.contains(category.id) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedCategories.insert(category.id)
                                            } else {
                                                selectedCategories.remove(category.id)
                                            }
                                        }
                                    )) {
                                        HStack(spacing: 12) {
                                            Text(category.emoji)
                                                .font(.system(size: 22))
                                            Text(category.name)
                                                .font(.system(size: 22))
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: customGreen))
                                    .scaleEffect(0.8)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    
                                    if category.id != availableCategories.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 16)
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(availableCategories.filter { selectedCategories.contains($0.id) }) { category in
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
                                                Toggle(isOn: Binding(
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
                                                )) {
                                                    HStack(spacing: 12) {
                                                        Text(subcategory.name)
                                                            .font(.system(size: 22))  // Match the font size of category toggles
                                                    }
                                                }
                                                .toggleStyle(SwitchToggleStyle(tint: customGreen))
                                                .scaleEffect(0.8)  // Make toggle smaller
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                
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
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    Spacer()
                    
                    // Next/Done Button
                    Button(action: {
                        if step == .categories {
                            step = .subcategories
                        } else {
                            finishSelection()
                        }
                    }) {
                        Text(step == .categories ? "Next" : "Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(customGreen)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
                }
                
                if showAddSubcategoryForm {
                    AddSubcategoryModal(
                        isPresented: $showAddSubcategoryForm,
                        newSubcategoryName: $newSubcategoryName,
                        onAdd: addSubcategory
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .presentationDragIndicator(.visible)
    }
    
    private var specializedSelectionView: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Green Header
                    ZStack {
                        Rectangle()
                            .fill(customGreen)
                            .frame(height: 110)
                            .edgesIgnoringSafeArea(.top)
                        
                        VStack {
                            Text("Add \(type == .saving ? "Savings" : "Debt")")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 45)
                        }
                    }
                    
                    // Subtitle text
                    Text(type == .saving ?
                         "Choose the savings goals you want to achieve." :
                         "Choose the debts you currently have.")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(availableCategories) { category in
                                Toggle(isOn: Binding(
                                    get: { selectedCategories.contains(category.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedCategories.insert(category.id)
                                        } else {
                                            selectedCategories.remove(category.id)
                                        }
                                    }
                                )) {
                                    HStack(spacing: 12) {
                                        Text(category.emoji)
                                            .font(.system(size: 22))
                                        Text(category.name)
                                            .font(.system(size: 22))
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: customGreen))
                                .scaleEffect(0.8)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                if category.id != availableCategories.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        let selected = availableCategories.filter { selectedCategories.contains($0.id) }
                        onSelect(selected)
                        isPresented = false
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(customGreen)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
                    .disabled(selectedCategories.isEmpty)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .presentationDragIndicator(.visible)
    }
    
    private var defaultCategoryView: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Green Header
                    ZStack {
                        Rectangle()
                            .fill(customGreen)
                            .frame(height: 110)
                            .edgesIgnoringSafeArea(.top)
                        
                        VStack {
                            Text("Add Category")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 45)
                        }
                    }
                    
                    // Subtitle text
                    Text("Choose the categories you want to add to your budget.")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(availableCategories) { category in
                                Toggle(isOn: Binding(
                                    get: { selectedCategories.contains(category.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedCategories.insert(category.id)
                                        } else {
                                            selectedCategories.remove(category.id)
                                        }
                                    }
                                )) {
                                    HStack(spacing: 12) {
                                        Text(category.emoji)
                                            .font(.system(size: 22))
                                        Text(category.name)
                                            .font(.system(size: 22))
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: customGreen))
                                .scaleEffect(0.8)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                if category.id != availableCategories.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        let selected = availableCategories.filter { selectedCategories.contains($0.id) }
                        onSelect(selected)
                        isPresented = false
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(customGreen)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
                    .disabled(selectedCategories.isEmpty)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .presentationDragIndicator(.visible)
    }
    
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
    
    private func finishSelection() {
            let selected = availableCategories.filter { selectedCategories.contains($0.id) }
            onSelect(selected)
            isPresented = false
        }
    }
    
private struct MinimalToggleStyle: ToggleStyle {
    let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    
    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .toggleStyle(SwitchToggleStyle(tint: customGreen))
            .scaleEffect(0.8)  // Makes the toggle slightly smaller
    }
}

struct AddSubcategoryModal: View {
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    @Binding var isPresented: Bool
    @Binding var newSubcategoryName: String
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Modal Header
            Text("Add New Subcategory")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            
            Text("Enter the name of your subcategory")
                .font(.system(size: 22))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            
            // Text Field for Subcategory Name
            TextField("Subcategory Name", text: $newSubcategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            
            // Add Button
            Button(action: {
                onAdd()
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Subcategory")
                }
                .foregroundColor(customGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .disabled(newSubcategoryName.isEmpty)
            .opacity(newSubcategoryName.isEmpty ? 0.6 : 1.0)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal, 40)
    }
}

struct SubcategorySelectionView: View {
    @Binding var isPresented: Bool
    let selectedCategories: [BudgetCategory]
    let onComplete: ([BudgetCategory]) -> Void
    @State private var selectedSubcategories: [UUID: Set<UUID>] = [:]
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Subcategories")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(customGreen)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(selectedCategories) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            // Category Header
                            HStack {
                                Text(category.emoji)
                                Text(category.name)
                                    .font(.headline)
                            }
                            .padding(.horizontal)
                            
                            // Subcategories
                            VStack(spacing: 0) {
                                ForEach(category.subcategories) { subcategory in
                                    ToggleRow(
                                        isOn: Binding(
                                            get: { selectedSubcategories[category.id]?.contains(subcategory.id) ?? false },
                                            set: { isSelected in
                                                if isSelected {
                                                    var subcats = selectedSubcategories[category.id] ?? Set<UUID>()
                                                    subcats.insert(subcategory.id)
                                                    selectedSubcategories[category.id] = subcats
                                                } else {
                                                    selectedSubcategories[category.id]?.remove(subcategory.id)
                                                }
                                            }
                                        ),
                                        icon: "",
                                        text: subcategory.name
                                    )
                                    
                                    if subcategory.id != category.subcategories.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            
            // Done Button
            Button(action: {
                var updatedCategories = selectedCategories
                for (categoryId, selectedSubcategoryIds) in selectedSubcategories {
                    if let categoryIndex = updatedCategories.firstIndex(where: { $0.id == categoryId }) {
                        updatedCategories[categoryIndex].subcategories = updatedCategories[categoryIndex].subcategories.map { subcategory in
                            var updatedSubcategory = subcategory
                            updatedSubcategory.isSelected = selectedSubcategoryIds.contains(subcategory.id)
                            return updatedSubcategory
                        }
                    }
                }
                onComplete(updatedCategories)
                isPresented = false
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(customGreen)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(selectedSubcategories.isEmpty)
        }
        .background(Color(.systemBackground))
        .onAppear {
            // Initialize selected subcategories from existing selections
            for category in selectedCategories {
                selectedSubcategories[category.id] = Set(
                    category.subcategories
                        .filter { $0.isSelected }
                        .map { $0.id }
                )
            }
        }
    }
}

// MARK: - Category Selection Sheet
struct CategorySelectionSheet: View {
    @Binding var isPresented: Bool
    let type: CategoryType
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var selectedCategories: Set<UUID> = []
    @State private var step: SelectionStep = .categories
    @State private var debtAmounts: [UUID: String] = [:]
    @State private var selectedDates: [UUID: Date] = [:]
    @State private var showDatePicker: UUID? = nil
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)
    
    enum SelectionStep {
        case categories
        case subcategories
        case debtDetails
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Green Header
                ZStack {
                    Rectangle()
                        .fill(customGreen)
                        .frame(height: 100)
                    
                    VStack(spacing: 8) {
                        Text(headerTitle)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                }
                
                if step == .subcategories {
                    Text("Choose the specific items to include in your budget.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                        .padding(.bottom, 8)
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        switch step {
                        case .categories:
                            categoriesView
                        case .subcategories:
                            subcategoriesView
                        case .debtDetails:
                            debtDetailsView
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Bottom button
                Button(action: handleNextStep) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(customGreen)
                }
                .padding(.horizontal)
                .padding(.bottom, 34)
                .disabled(!canProceed)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .edgesIgnoringSafeArea(.top)
            .navigationBarItems(
                leading: leadingBarButton,
                trailing: Button("Cancel") { isPresented = false }
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var headerTitle: String {
        switch step {
        case .categories:
            switch type {
            case .debt: return "Add Debt"
            case .need, .want: return "Add Expenses"
            case .saving: return "Add Savings"
            }
        case .subcategories:
            return "Select Details"
        case .debtDetails:
            return "Enter Debt Details"
        }
    }
    
    private var buttonTitle: String {
        switch step {
        case .categories:
            return type == .need ? "Next" : "Done"
        case .subcategories, .debtDetails:
            return "Done"
        }
    }
    
    private var canProceed: Bool {
        switch step {
        case .categories:
            return !selectedCategories.isEmpty
        case .subcategories:
            return true
        case .debtDetails:
            return debtAmounts.values.allSatisfy { !$0.isEmpty }
        }
    }
    
    @ViewBuilder
    private var leadingBarButton: some View {
        if step != .categories {
            Button("Back") {
                withAnimation {
                    step = step == .debtDetails ? .categories : .categories
                }
            }
        }
    }
    
    private var categoriesView: some View {
        ForEach(availableCategories) { category in
            CategoryRow(
                category: category,
                isSelected: selectedCategories.contains(category.id),
                onToggle: { isSelected in
                    if isSelected {
                        selectedCategories.insert(category.id)
                    } else {
                        selectedCategories.remove(category.id)
                    }
                }
            )
        }
    }
    
    private var subcategoriesView: some View {
        ForEach(selectedCategoriesArray) { category in
            SubcategoryToggleRow(
                subcategory: category.subcategories[0], // Or handle multiple subcategories as needed
                categoryId: category.id,
                store: budgetCategoryStore
            )
        }
    }
    
    private var debtDetailsView: some View {
        ForEach(selectedCategoriesArray) { category in
            DebtDetailsRow(
                category: category,
                amount: Binding(
                    get: { debtAmounts[category.id] ?? "" },
                    set: { debtAmounts[category.id] = $0 }
                ),
                date: Binding(
                    get: { selectedDates[category.id] ?? Date() },
                    set: { selectedDates[category.id] = $0 }
                ),
                showDatePicker: Binding(
                    get: { showDatePicker == category.id },
                    set: { _ in showDatePicker = category.id }
                )
            )
        }
    }
    
    private var availableCategories: [BudgetCategory] {
        budgetCategoryStore.categories.filter { $0.type == type && !$0.isSelected }
    }
    
    private var selectedCategoriesArray: [BudgetCategory] {
        availableCategories.filter { selectedCategories.contains($0.id) }
    }
    
    private func handleNextStep() {
        switch step {
        case .categories:
            if type == .need {
                withAnimation {
                    step = .subcategories
                }
            } else if type == .debt {
                withAnimation {
                    step = .debtDetails
                }
            } else {
                finishSelection()
            }
        case .subcategories, .debtDetails:
            finishSelection()
        }
    }
    
    private func finishSelection() {
        // Update selected categories in store
        for categoryId in selectedCategories {
            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == categoryId }) {
                budgetCategoryStore.categories[index].isSelected = true
                
                if type == .debt {
                    budgetCategoryStore.categories[index].amount = Double(debtAmounts[categoryId] ?? "0") ?? 0
                    budgetCategoryStore.categories[index].dueDate = selectedDates[categoryId]
                }
            }
        }
        
        isPresented = false
    }
}

// MARK: - Helper Views
struct CategoryRow: View {
    let category: BudgetCategory
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(category.emoji)
                Text(category.name)
                    .font(.system(size: 20))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { isSelected },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
        }
        .cornerRadius(12)
    }
}


struct SubcategoryToggleRow: View {
    let subcategory: BudgetSubCategory
    let categoryId: UUID
    let store: BudgetCategoryStore
    
    var body: some View {
        Toggle(subcategory.name, isOn: Binding(
            get: {
                if let categoryIndex = store.categories.firstIndex(where: { $0.id == categoryId }),
                   let subcategoryIndex = store.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                    return store.categories[categoryIndex].subcategories[subcategoryIndex].isSelected
                }
                return false
            },
            set: { newValue in
                if let categoryIndex = store.categories.firstIndex(where: { $0.id == categoryId }),
                   let subcategoryIndex = store.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                    store.categories[categoryIndex].subcategories[subcategoryIndex].isSelected = newValue
                }
            }
        ))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct DebtDetailsRow: View {
    let category: BudgetCategory
    @Binding var amount: String
    @Binding var date: Date
    @Binding var showDatePicker: Bool
    
    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let endComponents = DateComponents(year: calendar.component(.year, from: start) + 10, month: 12)
        let end = calendar.date(from: endComponents) ?? start
        return start...end
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(category.emoji)
                Text(category.name)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(UIColor.secondarySystemBackground))
            
            // Amount input
            HStack {
                Text("Amount:")
                Spacer()
                HStack {
                    Text("$")
                    TextField("0", text: $amount)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
            .padding()
            
            // Due date picker
            HStack {
                Text("Due date:")
                Spacer()
                Button(action: { showDatePicker.toggle() }) {
                    Text(date.formatted(.dateTime.month().year()))
                    Image(systemName: "calendar")
                }
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            if showDatePicker {
                DatePicker(
                    "Select date",
                    selection: $date,
                    in: dateRange,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
            }
        }
        .background(Color.white)
        .cornerRadius(10)
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var budgetCategoryStore = BudgetCategoryStore.shared
    @State private var showingDebtSelection = false
    @State private var showingExpenseSelection = false
    @State private var showingSavingsSelection = false
    @State private var budgieModel: BudgieModel
    @State private var paycheckAmountText: String
    @State private var paycheckAmount: Double? = nil
    @State private var paymentCadence: PaymentCadence
    @State private var allocations: [UUID: Double] = [:]
    @State private var showDetails = false
    @State private var expandedCategoryIndex: UUID? = nil
    @State private var isDisclaimerExpanded: Bool = false
    @State private var expandedSubCategoryIndex: UUID? = nil
    @State private var showCategorySelection = false
    @State private var showPopup = false
    @State private var isEditing = false
    @State private var showSavingsSelectionView = false
    @State private var selectedCategoryForEdit: BudgetCategory? = nil
    @State private var selectedSubcategoryForEdit: BudgetSubCategory? = nil
    @State private var itemToDelete: Any? = nil
    @State private var isShowingDeleteAlert = false
    @State private var isEditingAmounts: [UUID: Bool] = [:]
    @State private var editedAmounts: [UUID: Double] = [:]
    @FocusState private var isInputFocused: Bool
    @State private var selectedTab: BudgetTab = .yourBudget
    @State private var selectedCategories: [BudgetCategory]
    @State private var isMenuOpen = false
    @State private var hasBudgetingExperience: Bool
    @State private var categoryToAdd: BudgetCategory?
    @State private var showConfirmation = false
    @State private var viewPeriod: ViewPeriod = .perPaycheck
    @State private var isEditingPaycheck = false
    @State private var editedPaycheckAmount: String = ""
    @State private var isDropdownOpen = false
    @Namespace private var animation
    @State private var selectedCategoryType: CategoryType?
    @State private var hasDebt: Bool
    @State private var hasExpenses: Bool
    @State private var hasSavings: Bool
    
    init(selectedCategories: [BudgetCategory], paymentFrequency: PaymentCadence, paycheckAmountText: String, hasDebt: Bool, hasExpenses: Bool, hasSavings: Bool, hasBudgetingExperience: Bool) {
        // Initialize all @State properties with their initial values
        _hasBudgetingExperience = State(initialValue: hasBudgetingExperience)
        _hasDebt = State(initialValue: hasDebt)
        _hasExpenses = State(initialValue: hasExpenses)
        _hasSavings = State(initialValue: hasSavings)
        _paymentCadence = State(initialValue: paymentFrequency)
        _paycheckAmountText = State(initialValue: paycheckAmountText)
        _selectedCategories = State(initialValue: selectedCategories)
        _budgieModel = State(initialValue: BudgieModel(paycheckAmount: Double(paycheckAmountText) ?? 0.0))
    }
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    var totalMonthlyBudget: Double {
        guard let amount = paycheckAmount else { return 0 }
        return paymentCadence.monthlyEquivalent(from: amount)
    }
    
    var totalPerPaycheckBudget: Double {
        return paycheckAmount ?? 0
    }
    
    var budgetDeficitOrSurplus: Double {
        let totalAllocated = allocations.values.reduce(0, +)
        return totalPerPaycheckBudget - totalAllocated
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    customNavigationBar
                        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
                    
                    segmentedControlView
                    
                    if selectedTab == .yourBudget {
                        ScrollView {
                            VStack(spacing: 16) {
                                paycheckTotalView()
                                    .padding(.top, 8)
                                allocationListView()
                            }
                        }
                    } else if selectedTab == .perfectBudget {
                        PerfectBudgetView(paycheckAmount: paycheckAmount ?? 0, paymentCadence: paymentCadence)
                    } else if selectedTab == .affordability {
                        AffordabilityView(budgieModel: budgieModel)
                            .environmentObject(BudgetCategoryStore.shared)
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Only show action button when not on affordability view
                    if selectedTab != .affordability {
                        actionButton()
                            .padding(.bottom, 32)
                    }
                } // End of VStack
                
                // Menu overlay
                if isMenuOpen {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                isMenuOpen = false
                            }
                        }
                    
                    slideOutMenuView
                        .transition(.move(edge: .trailing))
                }
                
                
            } // End of ZStack
            .navigationBarHidden(true)
            .edgesIgnoringSafeArea(.all)
        } // End of NavigationView
        .sheet(isPresented: $showPopup) {
            EnhanceBudgetSheet(
                budgieModel: $budgieModel,
                showPopup: $showPopup,
                selectedCategories: $selectedCategories
            )
            .environmentObject(budgetCategoryStore)
            .presentationDetents([.fraction(0.75)])
            .presentationDragIndicator(.visible)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            formatAndCalculatePaycheckAmount()
            calculateBudget()
            populateInitialRecommendedAllocations()
        }
        .onChange(of: budgetCategoryStore.categories) { _ in
            updateScreen()
        }
        .onChange(of: selectedCategories) { _ in
            updateScreen()
        }
        .onReceive(NotificationCenter.default.publisher(for: .budgetUpdated)) { notification in
            if let userInfo = notification.userInfo,
               let categoryId = userInfo["categoryId"] as? UUID,
               let amount = userInfo["amount"] as? Double {
                allocations[categoryId] = amount
            }
            updateScreen()
        }
        .alert(isPresented: $showConfirmation) {
            let impact = calculateBudgetImpact()
            return Alert(
                title: Text("Add Category"),
                message: Text("Adding '\(categoryToAdd?.name ?? "")' will \(impact.change) your budget by \(formatCurrency(abs(impact.amount))).\nYour new \(impact.amount >= 0 ? "surplus" : "deficit") will be \(formatCurrency(abs(impact.newTotal)))."),
                primaryButton: .default(Text("Add")) {
                    if let category = categoryToAdd {
                        addCategoryToBudget(category)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(item: $selectedSubcategoryForEdit) { subcategory in
            if let category = selectedCategories.first(where: { $0.subcategories.contains(where: { $0.id == subcategory.id }) }) {
                EditCategoryView(category: category, subcategory: subcategory, budgieModel: $budgieModel) {
                    updateScreen()
                }
            }
        }
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text("Delete \(getItemName(itemToDelete))?"),
                message: Text("Are you sure you want to delete \(getItemName(itemToDelete))? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let item = itemToDelete {
                        deleteItem(item)
                        itemToDelete = nil
                    }
                },
                secondaryButton: .cancel() {
                    itemToDelete = nil
                }
            )
        }
    }
    
    // MARK: - Budget Impact Calculations
    private func calculateBudgetImpact() -> (change: String, amount: Double, newTotal: Double) {
        // Get current total allocated amount
        let currentTotal = allocations.values.reduce(0, +)
        
        // Calculate new amount for the category being added
        let newAmount = categoryToAdd.map { calculateRecommendedAmount(for: $0) } ?? 0
        
        // Calculate the new total after adding the category
        let newTotal = currentTotal + newAmount
        
        // Use nil coalescing to safely unwrap paycheckAmount
        let currentPaycheck = paycheckAmount ?? 0
        
        // Determine if this will increase or decrease the budget
        let change = newAmount >= 0 ? "increase" : "decrease"
        
        // Return the impact details with safely unwrapped paycheckAmount
        return (change, newAmount, currentPaycheck - newTotal)
    }
    
    // MARK: - Currency Formatting
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    // MARK: - Populate Initial Recommended Allocations
    private func populateInitialRecommendedAllocations() {
        guard !hasBudgetingExperience else { return }
        
        for category in selectedCategories {
            if let recommendedAmount = budgieModel.recommendedAllocations[category.id] {
                allocations[category.id] = recommendedAmount
            }
            
            for subcategory in category.subcategories {
                if let recommendedSubAmount = budgieModel.recommendedAllocations[subcategory.id] {
                    allocations[subcategory.id] = recommendedSubAmount
                }
            }
        }
    }
    
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        isMenuOpen.toggle()
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                .frame(width: 44)
            }
            
            Text("deep pockets")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(height: 44)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Segmented Control
    private var segmentedControlView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BudgetTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation {
                                selectedTab = tab
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(tab.emoji)
                                    .font(.system(size: 14))
                                Text(tab.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(
                                Group {
                                    if selectedTab == tab {
                                        customGreen  // Replace Color.black
                                    } else {
                                        Color.white
                                    }
                                }
                            )
                            .foregroundColor(selectedTab == tab ? .white : .primary)
                            .cornerRadius(10)  // Reduced from 16 to match other views
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)  // Match the corner radius
                                    .stroke(Color.gray.opacity(0.3), lineWidth: selectedTab == tab ? 0 : 1)
                            )
                        }
                        .id(tab)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 50)
            .padding(.vertical, 8)
            .onChange(of: selectedTab) { newTab in
                withAnimation {
                    proxy.scrollTo(newTab, anchor: .center)
                }
            }
        }
    }
    
    private func paycheckTotalView() -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Title Section with dark green background
                HStack {
                    Text("Your Income Overview")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Button(action: { /* Show income info */ }) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(customGreen)
                // Amount Display
                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(viewPeriod.suffix)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formattedAmount)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                
                Divider()
                
                // Deficit/Surplus Row
                HStack {
                    Text(budgetDeficitOrSurplus >= 0 ? "Surplus" : "Deficit")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(viewPeriod.suffix)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatAmount(getAdjustedAmount(abs(budgetDeficitOrSurplus))))
                        .font(.headline)
                        .foregroundColor(budgetDeficitOrSurplus >= 0 ? .green : .red)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                
                Divider()
                
                // Time Period Pills at the bottom
                HStack(spacing: 2) {
                    ForEach(ViewPeriod.allCases, id: \.self) { period in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewPeriod = period
                            }
                        }) {
                            Text(period.rawValue)
                                .font(.subheadline)
                                .fontWeight(viewPeriod == period ? .semibold : .regular)
                                .foregroundColor(viewPeriod == period ? .primary : Color.gray.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewPeriod == period ?
                                              Color(UIColor.systemGray6) :
                                                Color.clear)
                                        .animation(.easeInOut(duration: 0.2), value: viewPeriod)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Slide Out Menu
    private var slideOutMenuView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: {
                withAnimation {
                    isMenuOpen = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)
            
            Text("Menu")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                menuItem(title: "Profile", icon: "person.circle")
                menuItem(title: "Settings", icon: "gear")
                menuItem(title: "Help", icon: "questionmark.circle")
                menuItem(title: "About", icon: "info.circle")
            }
            
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width * 0.7)
        .padding()
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.vertical)
    }
    
    private func menuItem(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
    }
    
    // MARK: - Action Button
    private func actionButton() -> some View {
        Button(action: {
            withAnimation {
                showPopup.toggle()
                if !showPopup {
                    isEditing = false
                }
            }
        }) {
            HStack(spacing: 8) {
                Text("Recommendations")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "pencil")
                    .font(.system(size: 16))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black)
            .cornerRadius(10)  // Changed from Capsule() to a smaller corner radius
            .shadow(color: .gray, radius: 2, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
    }
    
    private func disclaimerSection() -> some View {
        VStack(spacing: 0) {
            // Header Button
            Button(action: {
                withAnimation {
                    isDisclaimerExpanded.toggle()
                }
            }) {
                HStack {
                    Text("How your budget is built")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    Image(systemName: isDisclaimerExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray5))
                .cornerRadius(10, corners: [.topLeft, .topRight])
            }
            
            // Expandable Content
            if isDisclaimerExpanded {
                VStack(spacing: 16) {
                    // Philosophy
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Budget Philosophy")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("This is YOUR budget - designed to be flexible and adapt to your needs. While we provide recommendations based on common financial principles, you have full control to adjust any category to match your unique situation.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Calculations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it's Calculated")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Your budget starts with your income and automatically suggests allocations across your chosen categories. These suggestions follow the 50/30/20 rule (needs/wants/savings) but can be fully customized. The app continuously recalculates your total budget and shows your surplus or deficit in real-time.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Features")
                            .font(.headline)
                            .foregroundColor(.primary)
                        VStack(alignment: .leading, spacing: 4) {
                            bulletPoint("View your budget by paycheck, monthly, or yearly")
                            bulletPoint("Add or remove categories anytime")
                            bulletPoint("Automatic recommendations based on your income")
                            bulletPoint("Real-time surplus/deficit tracking")
                            bulletPoint("Affordability calculator for major purchases")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .background(Color.white)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .padding(.bottom, 16)
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
    
    // New surplus section
    private var surplusRecommendationsSection: some View {
        VStack(spacing: 12) {
            // Header with adjusted amount
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
                Text("Recommended Categories")
                    .font(.subheadline)
                    .foregroundColor(.green)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatAmount(getAdjustedAmount(budgetDeficitOrSurplus)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text(viewPeriod.suffix)
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
            )
            
            // Recommended categories list
            VStack(spacing: 1) {
                ForEach(getRecommendedCategories(), id: \.id) { category in
                    recommendedCategoryRow(category)
                }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
        }
    }
    
    private func recommendedCategoryRow(_ category: BudgetCategory) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(category.emoji)
                    Text(category.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                }
                Text("Recommended: \(currencyFormatter.string(from: NSNumber(value: calculateRecommendedAmount(for: category))) ?? "$0")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                categoryToAdd = category
                showConfirmation = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }
    
    private func getRecommendedCategories() -> [BudgetCategory] {
        let availableCategories = budgetCategoryStore.categories.filter { category in
            !selectedCategories.contains(where: { $0.id == category.id }) &&
            category.type != .debt  // Exclude debt categories
        }
        
        return Array(availableCategories.sorted { $0.priority < $1.priority }.prefix(3))
    }
    
    // Update calculateRecommendedAmount to ensure it matches the preview amount
    private func calculateRecommendedAmount(for category: BudgetCategory) -> Double {
        // Calculate recommended allocations if not already done
        budgieModel.calculateRecommendedAllocations(selectedCategories: budgetCategoryStore.categories)
        
        // Get the recommended amount from budgieModel
        let recommendedAmount = budgieModel.recommendedAllocations[category.id] ?? 0
        
        // Make sure it doesn't exceed available surplus
        let availableSurplus = budgetDeficitOrSurplus
        return min(recommendedAmount, availableSurplus)
    }
    
    private func prioritizedCategories(type: CategoryType) -> [BudgetCategory] {
        let filteredCategories = selectedCategories.filter {
            if type == .need {
                return $0.type == .need || $0.type == .want
            }
            return $0.type == type
        }
        
        // Only sort by priority if there's a deficit
        if budgetDeficitOrSurplus < 0 {
            return filteredCategories.sorted(by: { $0.priority > $1.priority })
        }
        return filteredCategories
    }
    
    
    private func addCategoryToBudget(_ category: BudgetCategory) {
        // Calculate recommended amount
        let recommendedAmount = calculateRecommendedAmount(for: category)
        
        // Create new category with recommended amount
        var newCategory = category
        newCategory.isSelected = true
        newCategory.amount = recommendedAmount
        
        // Update category type flags based on the new category
        switch category.type {
        case .debt:
            hasDebt = true
        case .need, .want:
            hasExpenses = true
        case .saving:
            hasSavings = true
        }
        
        // Update budgetCategoryStore
        if !budgetCategoryStore.categories.contains(where: { $0.id == category.id }) {
            budgetCategoryStore.addCategory(
                name: category.name,
                emoji: category.emoji,
                allocationPercentage: category.allocationPercentage,
                subcategories: category.subcategories,
                description: category.description,
                type: category.type,
                amount: recommendedAmount,
                dueDate: nil,
                isSelected: true,
                priority: category.priority
            )
        } else if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
            budgetCategoryStore.categories[index].isSelected = true
            budgetCategoryStore.categories[index].amount = recommendedAmount
        }
        
        // Update selected categories immediately
        selectedCategories = budgetCategoryStore.categories.filter { $0.isSelected }
        
        // Update allocations
        allocations[newCategory.id] = recommendedAmount
        budgieModel.recommendedAllocations[newCategory.id] = recommendedAmount
        budgieModel.allocations[newCategory.id] = recommendedAmount
        
        // Force UI update with animation
        withAnimation {
            // Recalculate budget
            calculateBudget()
            
            // Post notification
            NotificationCenter.default.post(
                name: .budgetUpdated,
                object: nil,
                userInfo: [
                    "categoryId": newCategory.id,
                    "amount": recommendedAmount
                ]
            )
        }
        
        // Clear the addition state
        categoryToAdd = nil
        showPopup = false
        showConfirmation = false
    }
    
    private func getInfoText(for section: String) -> String {
        switch section {
        case "Debt":
            return "View and manage your debt payments and balances"
        case "Expenses":
            return "Track your regular monthly expenses and spending"
        case "Savings":
            return "Monitor your progress towards savings goals"
        default:
            return "View your budget information"
        }
    }
    
    private func sectionView(title: String, type: CategoryType, categories: [BudgetCategory], onAddTap: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            // Section Header
            SectionHeaderView(
                title: title,
                color: .white,
                infoText: getInfoText(for: title),
                type: type,
                onAddTap: onAddTap // Pass the handler
            )
            
            VStack(spacing: 8) {
                // Show existing categories if any
                if !categories.isEmpty {
                    ForEach(categories) { category in
                        categoryView(category)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(10)
        .padding(.bottom, 16)
    }

    
    // MARK: - Updated Category View
    private func categoryView(_ category: BudgetCategory) -> some View {
        let shouldHighlight = budgetDeficitOrSurplus < 0 && isHighlightedForRemoval(category)
        let categoryTotal = if category.type == .need || category.type == .want {
            // For expenses, always calculate from subcategories
            category.subcategories
                .filter { $0.isSelected }
                .reduce(0.0) { $0 + (allocations[$1.id] ?? 0) }
        } else {
            // For other types, use the category allocation
            allocations[category.id] ?? 0
        }
        
        return VStack(spacing: 0) {
            // Category Header
            HStack {
                Text("\(category.emoji) \(category.name)")
                    .font(.headline)
                    .fontWeight(.semibold)
                if shouldHighlight {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.8))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(formatAmount(getAdjustedAmount(categoryTotal)))
                        .font(.headline)
                        .foregroundColor(shouldHighlight ? .red.opacity(0.8) : Color.primary)
                    Text(viewPeriod.suffix)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Image(systemName: expandedCategoryIndex == category.id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.black)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandedCategoryIndex = expandedCategoryIndex == category.id ? nil : category.id
                }
            }
            
            if expandedCategoryIndex == category.id {
                VStack(spacing: 0) {
                    // Warning message for highlighted items
                    if shouldHighlight {
                        HStack(spacing: 6) {
                            Text("Consider adjusting this category based on priority")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                    
                    // Recommended Amount
                    if let recommendedAmount = budgieModel.recommendedAllocations[category.id] {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommended Amount:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(currencyFormatter.string(from: NSNumber(value: recommendedAmount)) ?? "$0")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(UIColor.secondarySystemBackground))
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                    
                    // Description
                    descriptionView(for: category)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Subcategories (if any)
                    if !category.subcategories.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Subcategories")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            
                            ForEach(category.subcategories.filter { $0.isSelected }) { subcategory in
                                VStack(spacing: 0) {
                                    HStack {
                                        Text(subcategory.name)
                                            .font(.subheadline)
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text(formatAmount(getAdjustedAmount(allocations[subcategory.id] ?? 0)))
                                                .font(.subheadline)
                                            Text(viewPeriod.suffix)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .onTapGesture {
                                        withAnimation {
                                            expandedSubCategoryIndex = expandedSubCategoryIndex == subcategory.id ? nil : subcategory.id
                                        }
                                    }
                                    
                                    if expandedSubCategoryIndex == subcategory.id {
                                        VStack(spacing: 0) {
                                            if let recommendedAmount = budgieModel.recommendedAllocations[subcategory.id] {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Recommended Amount:")
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.secondary)
                                                    Text(currencyFormatter.string(from: NSNumber(value: recommendedAmount)) ?? "$0")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.primary)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 16)
                                                .background(Color(UIColor.secondarySystemBackground))
                                            }
                                            
                                            Divider()
                                                .background(Color.gray.opacity(0.3))
                                            
                                            descriptionView(for: subcategory)
                                            
                                            Divider()
                                                .background(Color.gray.opacity(0.3))
                                            
                                            editDeleteButtons(for: subcategory)
                                        }
                                    }
                                    
                                    if subcategory.id != category.subcategories.filter({ $0.isSelected }).last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                    
                    // Due Date if applicable
                    if let dueDate = category.dueDate {
                        dueDateView(for: dueDate)
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                    
                    // Edit/Delete buttons
                    editDeleteButtons(for: category)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            shouldHighlight ?
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
            : nil
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Updated Subcategory View
    private func subcategoryView(for subcategory: BudgetSubCategory, in category: BudgetCategory) -> some View {
        VStack(spacing: 0) {
            // Subcategory row
            HStack {
                Text(subcategory.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(currencyFormatter.string(from: NSNumber(value: allocations[subcategory.id] ?? 0)) ?? "$0")
                        .font(.subheadline)
                    Text("/paycheck")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Image(systemName: expandedSubCategoryIndex == subcategory.id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.black)
                    .font(.footnote)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandedSubCategoryIndex = expandedSubCategoryIndex == subcategory.id ? nil : subcategory.id
                }
            }
            
            if expandedSubCategoryIndex == subcategory.id {
                VStack(spacing: 0) {
                    // Recommended Amount
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended Amount:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        HStack {
                            Text(currencyFormatter.string(from: NSNumber(value: budgieModel.recommendedAllocations[subcategory.id] ?? 0)) ?? "$0")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("/paycheck")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(UIColor.secondarySystemBackground))
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Description
                    descriptionView(for: subcategory)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Edit/Delete buttons
                    editDeleteButtons(for: subcategory)
                }
            }
        }
        .background(Color.white)
    }
    
    private func isHighlightedForRemoval(_ category: BudgetCategory) -> Bool {
        guard budgetDeficitOrSurplus < 0 else { return false }
        
        var remainingDeficit = abs(budgetDeficitOrSurplus)
        let sortedCategories = selectedCategories.sorted { $0.priority > $1.priority }
        
        for cat in sortedCategories {
            if remainingDeficit <= 0 {
                break
            }
            if cat.id == category.id {
                return true
            }
            remainingDeficit -= (allocations[cat.id] ?? 0)
        }
        
        return false
    }
    
    // MARK: - Edit/Delete Buttons
    private func editDeleteButtons(for item: Any) -> some View {
        let id = (item as? BudgetCategory)?.id ?? (item as? BudgetSubCategory)?.id ?? UUID()
        let isEditingItem = isEditingAmounts[id] ?? false
        let itemAmount = getItemAmount(item)
        
        return VStack(spacing: 8) {
            if isEditingItem {
                CurrencyTextField(value: Binding(
                    get: { self.editedAmounts[id] ?? itemAmount },
                    set: { self.editedAmounts[id] = $0 }
                ))
                .frame(height: 44)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }
            
            HStack(spacing: 8) {
                Button(action: {
                    if isEditingItem {
                        updateItemAmount(item)
                        isEditingAmounts[id] = false
                    } else {
                        editedAmounts[id] = itemAmount
                        isEditingAmounts[id] = true
                    }
                }) {
                    HStack {
                        Image(systemName: isEditingItem ? "checkmark" : "pencil")
                        Text(isEditingItem ? "Done" : "Edit")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    itemToDelete = item
                    isShowingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Update Item Amount
    private func updateItemAmount(_ item: Any) {
        let id = (item as? BudgetCategory)?.id ?? (item as? BudgetSubCategory)?.id ?? UUID()
        if let newAmount = editedAmounts[id] {
            if let category = item as? BudgetCategory {
                // For categories, only update non-expense categories directly
                if category.type != .need && category.type != .want {
                    if let index = selectedCategories.firstIndex(where: { $0.id == category.id }) {
                        selectedCategories[index].amount = newAmount
                    }
                }
            } else if let subcategory = item as? BudgetSubCategory,
                      let category = selectedCategories.first(where: { $0.subcategories.contains(where: { $0.id == subcategory.id }) }) {
                // For subcategories, update both the subcategory and recalculate the parent category total
                budgieModel.updateSubcategory(category: category, subcategory: subcategory, newAmount: newAmount)
            }
            calculateBudget()
        }
    }
    
    // MARK: - Expense Category View
    private func expenseCategoryView(_ category: BudgetCategory) -> some View {
        let totalAmount = category.subcategories
            .filter { $0.isSelected }
            .reduce(0.0) { $0 + (allocations[$1.id] ?? 0) }
        
        return VStack(spacing: 0) {
            // Category Header
            HStack {
                Text("\(category.emoji) \(category.name)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(formatAmount(getAdjustedAmount(totalAmount)))
                        .font(.headline)
                    Text("/paycheck")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Image(systemName: expandedCategoryIndex == category.id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.black)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandedCategoryIndex = expandedCategoryIndex == category.id ? nil : category.id
                }
            }
            
            if expandedCategoryIndex == category.id {
                VStack(spacing: 0) {
                    // Show Subcategories
                    ForEach(category.subcategories.filter { $0.isSelected }) { subcategory in
                        subcategoryView(for: subcategory, in: category)
                        
                        if subcategory.id != category.subcategories.filter({ $0.isSelected }).last?.id {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Delete Item
    private func deleteItem(_ item: Any) {
        if let category = item as? BudgetCategory {
            deleteCategory(category)
        } else if let subcategory = item as? BudgetSubCategory {
            deleteSubcategory(subcategory)
        }
    }
    
    // MARK: - Get Item Name
    private func getItemName(_ item: Any?) -> String {
        if let category = item as? BudgetCategory {
            return category.name
        } else if let subcategory = item as? BudgetSubCategory {
            return subcategory.name
        }
        return ""
    }
    
    // MARK: - Get Item Amount
    private func getItemAmount(_ item: Any) -> Double {
        if let category = item as? BudgetCategory {
            return category.amount ?? 0
        } else if let subcategory = item as? BudgetSubCategory {
            return allocations[subcategory.id] ?? 0
        }
        return 0
    }
    
    // MARK: - Delete Category
    private func deleteCategory(_ category: BudgetCategory) {
        // Update budgetCategoryStore
        if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
            budgetCategoryStore.categories[index].isSelected = false
        }
        // Remove from selectedCategories
        selectedCategories.removeAll { $0.id == category.id }
        // Remove from allocations
        allocations.removeValue(forKey: category.id)
        // Recalculate budget
        calculateBudget()
    }

    
    // MARK: - Delete Subcategory
    private func deleteSubcategory(_ subcategory: BudgetSubCategory) {
        if let categoryIndex = selectedCategories.firstIndex(where: { $0.subcategories.contains(where: { $0.id == subcategory.id }) }) {
            // Remove from selectedCategories
            selectedCategories[categoryIndex].subcategories.removeAll { $0.id == subcategory.id }
            // Update budgetCategoryStore
            if let storeCategoryIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == selectedCategories[categoryIndex].id }) {
                budgetCategoryStore.categories[storeCategoryIndex].subcategories.removeAll { $0.id == subcategory.id }
            }
            // Remove from allocations
            allocations.removeValue(forKey: subcategory.id)
            // Recalculate budget
            calculateBudget()
        }
    }
    
    // MARK: - Description View
    private func descriptionView(for item: Any) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(description(for: item))
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Due Date View
    private func dueDateView(for dueDate: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debt Due Date")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(dateFormatter.string(from: dueDate))
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Description Helper
    private func description(for item: Any) -> String {
        if let category = item as? BudgetCategory {
            return category.description
        } else if let subcategory = item as? BudgetSubCategory {
            return subcategory.description
        }
        return ""
    }
    
    // MARK: - Format and Calculate Paycheck Amount
    private func formatAndCalculatePaycheckAmount() {
        let filteredText = paycheckAmountText.filter { "0123456789.".contains($0) }
        if let value = Double(filteredText) {
            paycheckAmount = value
            paycheckAmountText = currencyFormatter.string(from: NSNumber(value: value)) ?? ""
            showDetails = true
            budgieModel.paycheckAmount = value
            calculateBudget()
        } else {
            showDetails = false
        }
    }
    
    // Update calculateBudget to include all selected categories
    private func calculateBudget() {
        budgieModel.paymentCadence = paymentCadence
        let relevantCategories = selectedCategories.filter { category in
            switch category.type {
            case .debt:
                return hasDebt
            case .need, .want:
                return hasExpenses
            case .saving:
                return hasSavings
            }
        }
        budgieModel.calculateAllocations(selectedCategories: selectedCategories) // Changed to use all selected categories
        budgieModel.calculateRecommendedAllocations(selectedCategories: selectedCategories)
        allocations = budgieModel.allocations
        
        if !hasBudgetingExperience {
            populateInitialRecommendedAllocations()
        }
    }
    
    // MARK: - Update Screen
    private func updateScreen() {
        calculateBudget()
        selectedCategories = budgetCategoryStore.categories.filter { $0.isSelected }
    }
    
    // MARK: - BudgetTab Enum
    enum BudgetTab: String, CaseIterable {
        case yourBudget
        case affordability
        case perfectBudget
        
        var title: String {
            switch self {
            case .yourBudget: return "Your Budget"
            case .affordability: return "Affordability"
            case .perfectBudget: return "Perfect Budget"
            }
        }
        
        var emoji: String {
            switch self {
            case .yourBudget: return "💰"
            case .affordability: return "🏠"
            case .perfectBudget: return "✨"
            }
        }
    }
    
    // MARK: - Date Formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    // Helper to format amounts based on view period
    private var formattedAmount: String {
        let amount = switch viewPeriod {
        case .perPaycheck:
            paycheckAmount ?? 0
        case .monthly:
            (paycheckAmount ?? 0) * paymentCadence.numberOfPaychecksPerMonth
        case .yearly:
            (paycheckAmount ?? 0) * paymentCadence.numberOfPaychecksPerMonth * 12
        }
        return formatAmount(amount)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    // Helper to adjust amounts based on view period
    private func getAdjustedAmount(_ amount: Double) -> Double {
        switch viewPeriod {
        case .perPaycheck:
            return amount
        case .monthly:
            return amount * paymentCadence.numberOfPaychecksPerMonth
        case .yearly:
            return amount * paymentCadence.numberOfPaychecksPerMonth * 12
        }
    }
}

extension ContentView {
    private func allocationListView() -> some View {
        VStack(spacing: 16) {
            // Savings Section
            sectionView(
                title: "Savings",
                type: .saving,
                categories: prioritizedCategories(type: .saving)
            ) {
                showSavingsSelectionView = true
            }
            .sheet(isPresented: $showSavingsSelectionView) {
                ContentSavingsSelectionView(isPresented: $showSavingsSelectionView)
                    .environmentObject(budgetCategoryStore)
            }
            
            // Expenses Section
            sectionView(
                title: "Expenses",
                type: .need,
                categories: prioritizedCategories(type: .need)
            ) {
                showingExpenseSelection = true
            }
            .sheet(isPresented: $showingExpenseSelection) {
                ContentExpenseSelectionView(isPresented: $showingExpenseSelection)
                    .environmentObject(budgetCategoryStore)
            }
            
            // Debt Section
            sectionView(
                title: "Debt",
                type: .debt,
                categories: prioritizedCategories(type: .debt)
            ) {
                showingDebtSelection = true
            }
            .sheet(isPresented: $showingDebtSelection) {
                ContentDebtSelectionView(isPresented: $showingDebtSelection)
                    .environmentObject(budgetCategoryStore)
            }
        }
        .padding(.horizontal)
    }
}
