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
            // Custom Add/Recommended Toggle
            HStack(spacing: 0) {
                tabButton(for: .add)
                tabButton(for: .recommended)
            }
            .padding(.horizontal)
            .padding(.top)
            
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
        .cornerRadius(20, corners: [.topLeft, .topRight])
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
    }
    
    private func tabButton(for tab: EditBudgetTab) -> some View {
        Button(action: {
            withAnimation {
                currentTab = tab
            }
        }) {
            Text(tab.title)
                .font(.subheadline)
                .foregroundColor(currentTab == tab ? .black : .gray)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(currentTab == tab ? Color.white : Color.clear)
                .cornerRadius(20)
        }
    }
    
    private func addCategoriesView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Categories")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top)
            
            Text("Add categories that are missing from your current budget.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
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
            Text("Recommended Changes")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top)
            
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
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
            
            if expandedSection == section {
                VStack(spacing: 12) {
                    ForEach(categoriesForSection(section), id: \.id) { category in
                        if !selectedCategories.contains(where: { $0.id == category.id }) {
                            categoryRow(for: category)
                        }
                    }
                    
                    addCustomCategoryButton()
                }
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    private func categoryRow(for category: BudgetCategory) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.emoji)
                    Text(category.name)
                        .font(.headline)
                }
                Text("Recommended: \(formatCurrency(budgieModel.recommendedAllocations[category.id] ?? 0))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                categoryToAdd = category
                showConfirmation = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.black)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func addCustomCategoryButton() -> some View {
        Button(action: {
            showAddCategoryForm = true
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Custom Category")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
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
        var newCategory = category
        newCategory.isSelected = true
        newCategory.amount = budgieModel.recommendedAllocations[category.id] ?? 0

        if !budgetCategoryStore.categories.contains(where: { $0.id == category.id }) {
            budgetCategoryStore.addCategory(newCategory)
        } else if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
            budgetCategoryStore.categories[index] = newCategory
        }

        // Update selectedCategories
        if !selectedCategories.contains(where: { $0.id == newCategory.id }) {
            selectedCategories.append(newCategory)
        } else if let index = selectedCategories.firstIndex(where: { $0.id == newCategory.id }) {
            selectedCategories[index] = newCategory
        }

        // Update budgieModel
        budgieModel.updateCategory(newCategory, newAmount: newCategory.amount ?? 0)
        
        // Recalculate budget
        budgieModel.calculateAllocations(selectedCategories: selectedCategories)
        
        // Close the sheet
        showPopup = false
    }
    
    private func calculateBudgetImpact() -> (change: String, amount: Double, newTotal: Double) {
        let currentTotal = budgieModel.allocations.values.reduce(0, +)
        let newAmount = budgieModel.recommendedAllocations[categoryToAdd?.id ?? UUID()] ?? 0
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

enum EditBudgetTab: String {
    case add
    case recommended
    
    var title: String {
        rawValue.capitalized
    }
}

enum CategorySection: String {
    case debt
    case expenses
    case savings
    
    var title: String {
        rawValue.capitalized
    }
}

// MARK: - Custom Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
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

extension Notification.Name {
    static let budgetUpdated = Notification.Name("budgetUpdated")
}
