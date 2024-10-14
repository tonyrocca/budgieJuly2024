import SwiftUI

struct EnhanceBudgetSheet: View {
    @Binding var budgieModel: BudgieModel
    @Binding var showPopup: Bool
    @Binding var selectedCategories: [BudgetCategory]
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var currentTab: EditBudgetTab = .add
    @State private var expandedSection: CategorySection?
    @State private var showAddCategoryForm = false
    @State private var newCategoryName = ""
    @State private var newCategoryType: CategoryType = .need
    @State private var currentSection: CategorySection = .expenses
    @State private var toggledCategories: Set<UUID> = []

    let screenHeight = UIScreen.main.bounds.height
    let sheetHeight: CGFloat = UIScreen.main.bounds.height * 0.75
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Switcher
            Picker("Edit Budget Options", selection: $currentTab) {
                Text("Add").tag(EditBudgetTab.add)
                Text("Recommended").tag(EditBudgetTab.recommended)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top)
            
            // Content based on selected tab
            if currentTab == .add {
                addCategoryView()
            } else {
                Text("Recommended functionality coming soon")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            Spacer()
            
            // Done Button
            Button(action: {
                addSelectedCategoriesToBudget()
                withAnimation {
                    showPopup = false
                }
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                                       startPoint: .leading,
                                       endPoint: .trailing)
                    )
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
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
    }
    
    private func addCategoryView() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                categoryDropdown(for: .debt)
                categoryDropdown(for: .expenses)
                categoryDropdown(for: .savings)
            }
            .padding(.top)
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
                        currentSection = section
                    }
                }
            }) {
                HStack {
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
            
            if expandedSection == section {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(categoriesForSection(section), id: \.id) { category in
                        if !selectedCategories.contains(where: { $0.id == category.id }) {
                            Toggle(isOn: Binding(
                                get: { toggledCategories.contains(category.id) },
                                set: { newValue in
                                    if newValue {
                                        toggledCategories.insert(category.id)
                                    } else {
                                        toggledCategories.remove(category.id)
                                    }
                                }
                            )) {
                                HStack {
                                    Text(category.emoji)
                                    Text(category.name)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    
                    Button(action: {
                        showAddCategoryForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Custom Category")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    private func addCustomCategoryForm() -> some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $newCategoryName)
                
                Picker("Category Type", selection: $newCategoryType) {
                    ForEach(typeOptions(for: currentSection), id: \.self) { type in
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
            emoji: "🔹", // You might want to let users choose an emoji
            allocationPercentage: 0.0,
            subcategories: [],
            description: "Custom category",
            type: newCategoryType,
            isSelected: false
        )
        budgetCategoryStore.addCategory(newCategory)
        toggledCategories.insert(newCategory.id)
        newCategoryName = ""
    }
    
    private func categoriesForSection(_ section: CategorySection) -> [BudgetCategory] {
        switch section {
        case .debt:
            return budgetCategoryStore.categories.filter { $0.type == .debt }
        case .expenses:
            return budgetCategoryStore.categories.filter { $0.type == .need || $0.type == .want }
        case .savings:
            return budgetCategoryStore.categories.filter { $0.type == .saving }
        }
    }
    
    private func typeOptions(for section: CategorySection) -> [CategoryType] {
        switch section {
        case .debt:
            return [.debt]
        case .expenses:
            return [.need, .want]
        case .savings:
            return [.saving]
        }
    }
    
    private func addSelectedCategoriesToBudget() {
        for categoryId in toggledCategories {
            if let category = budgetCategoryStore.categories.first(where: { $0.id == categoryId }) {
                var updatedCategory = category
                updatedCategory.isSelected = true
                if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == categoryId }) {
                    budgetCategoryStore.categories[index] = updatedCategory
                }
                if !selectedCategories.contains(where: { $0.id == categoryId }) {
                    selectedCategories.append(updatedCategory)
                }
            }
        }
    }
}

enum EditBudgetTab {
    case add
    case recommended
}

enum CategorySection: String {
    case debt
    case expenses
    case savings
    
    var title: String {
        self.rawValue.capitalized
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
