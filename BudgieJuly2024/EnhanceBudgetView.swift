import SwiftUI

struct EnhanceBudgetSheet: View {
    @Binding var budgieModel: BudgieModel
    @Binding var showPopup: Bool
    @Binding var selectedCategories: [BudgetCategory]
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var currentTab: EditBudgetTab = .add
    @State private var showAddCategoryForm = false
    @State private var newCategoryName = ""
    @State private var newCategoryType: CategoryType = .need
    @State private var expandedSection: CategorySection?
    @State private var showConfirmation = false
    @State private var categoryToAdd: BudgetCategory?
    
    let screenHeight = UIScreen.main.bounds.height
    let sheetHeight: CGFloat = UIScreen.main.bounds.height * 0.75
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Add/Recommend Toggle
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EditBudgetTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation {
                                    currentTab = tab
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
                                .background(
                                    Group {
                                        if currentTab == tab {
                                            LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                                                           startPoint: .topLeading,
                                                           endPoint: .bottomTrailing)
                                        } else {
                                            Color.white
                                        }
                                    }
                                )
                                .foregroundColor(currentTab == tab ? .white : .primary)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: currentTab == tab ? 0 : 1)
                                )
                            }
                            .id(tab)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 50)
                .padding(.vertical, 8)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal)
            
            // Content based on selected tab
            if currentTab == .add {
                addCategoriesView()
            } else {
                recommendedCategoriesView()
            }
            
            Spacer()
        }
        .frame(height: sheetHeight)
        .background(Color(UIColor.systemGroupedBackground))
        .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
        .offset(y: max(offset + screenHeight - sheetHeight, 0))
        .animation(.interactiveSpring(), value: isDragging)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    if value.translation.height > 0 {
                        offset = value.translation.height
                    }
                }
                .onEnded { value in
                    isDragging = false
                    if value.translation.height > sheetHeight / 3 {
                        showPopup = false
                    } else {
                        offset = 0
                    }
                }
        )
        .sheet(isPresented: $showAddCategoryForm) {
            addCustomCategoryForm()
        }
        .alert(isPresented: $showConfirmation) {
            confirmationAlert()
        }
        .onAppear {
            // Calculate recommended allocations when sheet appears
            budgieModel.calculateRecommendedAllocations(selectedCategories: budgetCategoryStore.categories)
        }
    }
    
    private func addCategoriesView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Categories")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Add categories that are missing from your current budget.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            ScrollView {
                VStack(spacing: 16) {
                    categoryDropdown(for: .debt)
                    categoryDropdown(for: .expenses)
                    categoryDropdown(for: .savings)
                }
                .padding(.top)
            }
        }
    }
    
    private func recommendedCategoriesView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recommended Changes")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Suggestions to improve your budget allocation.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            Spacer()
            
            Text("Recommended changes coming soon!")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
        }
    }
    
    private func categoryDropdown(for section: CategorySection) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    if expandedSection == section {
                        expandedSection = nil
                    } else {
                        expandedSection = section
                    }
                }
            }) {
                HStack {
                    Text("\(section.emoji) \(section.title)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
            }
            
            if expandedSection == section {
                VStack(spacing: 1) {
                    ForEach(categoriesForSection(section), id: \.id) { category in
                        if !selectedCategories.contains(where: { $0.id == category.id }) {
                            categoryRow(for: category)
                        }
                    }
                    
                    addCustomCategoryButton()
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .background(Color(UIColor.secondarySystemBackground))
                .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func categoryRow(for category: BudgetCategory) -> some View {
        let recommendedAmount = calculateRecommendedAmount(for: category)
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(category.emoji)
                    Text(category.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                }
                Text("Recommended: \(formatCurrency(recommendedAmount))")
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
    
    private func calculateRecommendedAmount(for category: BudgetCategory) -> Double {
        let monthlyIncome = budgieModel.paycheckAmount * budgieModel.paymentCadence.numberOfPaychecksPerMonth
        
        let recommendedPercentages: [String: Double] = [
            "Housing": 0.30,
            "Transportation": 0.15,
            "Food": 0.12,
            "Healthcare": 0.10,
            "Utilities": 0.08,
            "Personal Care": 0.05,
            "Entertainment": 0.05,
            "Subscriptions": 0.03,
            "Education": 0.05,
            "Pets": 0.03
        ]
        
        let savingsPercentages: [String: Double] = [
            "Emergency Fund": 0.10,
            "Vacation": 0.05,
            "New Car": 0.05,
            "Home Renovation": 0.07,
            "Investment": 0.10,
            "Wedding": 0.05,
            "Education Fund": 0.05,
            "Retirement": 0.15,
            "House Down Payment": 0.10,
            "College Fund": 0.10,
            "Gadgets": 0.03,
            "Charity": 0.05,
            "Business Investment": 0.10,
            "Clothing Fund": 0.03
        ]
        
        switch category.type {
        case .need, .want:
            return monthlyIncome * (recommendedPercentages[category.name] ?? 0.05)
        case .saving:
            return monthlyIncome * (savingsPercentages[category.name] ?? 0.05)
        case .debt:
            return category.amount ?? (monthlyIncome * 0.1)
        }
    }
    
    private func addCustomCategoryButton() -> some View {
        Button(action: {
            showAddCategoryForm = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue.opacity(0.8))
                Text("Add Custom Category")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.08))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
    }
    
    private func addCustomCategoryForm() -> some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $newCategoryName)
                
                Picker("Category Type", selection: $newCategoryType) {
                    ForEach([CategoryType.debt, .need, .want, .saving], id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
            }
            .navigationBarTitle("Add Custom Category", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    showAddCategoryForm = false
                },
                trailing: Button("Add") {
                    addCustomCategory()
                    showAddCategoryForm = false
                }
            )
        }
    }
    
    private func addCustomCategory() {
        let newCategory = BudgetCategory(
            name: newCategoryName,
            emoji: "🔹",
            allocationPercentage: 0.0,
            subcategories: [],
            description: "Custom category",
            type: newCategoryType,
            isSelected: true
        )
        categoryToAdd = newCategory
        showConfirmation = true
    }
    
    private func confirmationAlert() -> Alert {
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
    
    private func addCategoryToBudget(_ category: BudgetCategory) {
        // Calculate recommended amount
        let recommendedAmount = calculateRecommendedAmount(for: category)
        
        // Create new category with recommended amount
        var newCategory = category
        newCategory.isSelected = true
        newCategory.amount = recommendedAmount
        
        // Update budgetCategoryStore
        if !budgetCategoryStore.categories.contains(where: { $0.id == category.id }) {
            budgetCategoryStore.addCategory(newCategory)
        } else if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
            budgetCategoryStore.categories[index] = newCategory
        }
        
        // Update selected categories
        if !selectedCategories.contains(where: { $0.id == newCategory.id }) {
            selectedCategories.append(newCategory)
        } else if let index = selectedCategories.firstIndex(where: { $0.id == newCategory.id }) {
            selectedCategories[index] = newCategory
        }
        
        // Update budgie model allocations
        budgieModel.allocations[newCategory.id] = recommendedAmount
        budgieModel.recommendedAllocations[newCategory.id] = recommendedAmount
        budgieModel.updateCategory(newCategory, newAmount: recommendedAmount)
        
        // Force recalculate all allocations
        let updatedCategories = selectedCategories.map { category -> BudgetCategory in
            var updatedCategory = category
            if category.id == newCategory.id {
                updatedCategory.amount = recommendedAmount
            }
            return updatedCategory
        }
        
        budgieModel.calculateAllocations(selectedCategories: updatedCategories)
        budgieModel.calculateRecommendedAllocations(selectedCategories: updatedCategories)
        budgieModel.calculatePerfectBudget(selectedCategories: updatedCategories)
        
        // Update allocations in ContentView's state
        NotificationCenter.default.post(
            name: .budgetUpdated,
            object: nil,
            userInfo: ["categoryId": newCategory.id, "amount": recommendedAmount]
        )
        
        showPopup = false
    }
    
    private func calculateBudgetImpact() -> (change: String, amount: Double, newTotal: Double) {
        let currentTotal = budgieModel.allocations.values.reduce(0, +)
        let newAmount = categoryToAdd.map { calculateRecommendedAmount(for: $0) } ?? 0
        let newTotal = currentTotal + newAmount
        let change = newAmount >= 0 ? "increase" : "decrease"
        return (change, newAmount, budgieModel.paycheckAmount - newTotal)
    }
    
    private func categoriesForSection(_ section: CategorySection) -> [BudgetCategory] {
        budgetCategoryStore.categories.filter { category in
            switch section {
            case .debt:
                return category.type == .debt
            case .expenses:
                return category.type == .need || category.type == .want
            case .savings:
                return category.type == .saving
            }
        }.filter { !selectedCategories.contains($0) }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}


enum EditBudgetTab: String, CaseIterable {
    case add
    case recommended
    
    var title: String {
        switch self {
        case .add:
            return "Add Categories"
        case .recommended:
            return "Recommendations"
        }
    }
    
    var emoji: String {
        switch self {
        case .add:
            return "➕"
        case .recommended:
            return "📊"
        }
    }
}

enum CategorySection: String {
    case debt
    case expenses
    case savings
    
    var title: String {
        rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .debt:
            return "💳"
        case .expenses:
            return "💸"
        case .savings:
            return "💰"
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

extension Notification.Name {
    static let budgetUpdated = Notification.Name("budgetUpdated")
}
