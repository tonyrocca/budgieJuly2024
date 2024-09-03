import SwiftUI

struct ContentView: View {
    @StateObject private var budgetCategoryStore = BudgetCategoryStore.shared
    @State private var budgieModel: BudgieModel
    @State private var paycheckAmountText: String
    @State private var paycheckAmount: Double? = nil
    @State private var paymentCadence: PaymentCadence
    @State private var allocations: [UUID: Double] = [:]
    @State private var showDetails = false
    @State private var expandedCategoryIndex: UUID? = nil
    @State private var expandedSubCategoryIndex: UUID? = nil
    @State private var showCategorySelection = false
    @State private var showPopup = false
    @State private var isEditing = false
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

    let hasDebt: Bool
    let hasExpenses: Bool
    let hasSavings: Bool

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    init(selectedCategories: [BudgetCategory], paymentFrequency: PaymentCadence, paycheckAmountText: String, hasDebt: Bool, hasExpenses: Bool, hasSavings: Bool) {
        self._paymentCadence = State(initialValue: paymentFrequency)
        self._paycheckAmountText = State(initialValue: paycheckAmountText)
        self._budgieModel = State(initialValue: BudgieModel(paycheckAmount: Double(paycheckAmountText) ?? 0.0))
        self._selectedCategories = State(initialValue: selectedCategories)
        self.hasDebt = hasDebt
        self.hasExpenses = hasExpenses
        self.hasSavings = hasSavings
    }

    var totalMonthlyBudget: Double {
        guard let amount = paycheckAmount else { return 0 }
        return paymentCadence.monthlyEquivalent(from: amount)
    }

    var totalPerPaycheckBudget: Double {
        guard let amount = paycheckAmount else { return 0 }
        return amount
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
                        Text("Affordability View")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 20)

                    actionButton()
                        .padding(.bottom, 32)
                }

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
            }
            .navigationBarHidden(true)
            .edgesIgnoringSafeArea(.all)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(budgetCategoryStore)
        .onAppear {
            formatAndCalculatePaycheckAmount()
            calculateBudget()
        }
        .onChange(of: budgetCategoryStore.categories) { _ in
            updateScreen()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .sheet(item: $selectedCategoryForEdit) { category in
            EditCategoryView(category: category, budgieModel: $budgieModel) {
                updateScreen()
            }
        }
        .sheet(item: $selectedSubcategoryForEdit) { subcategory in
            if let category = selectedCategories.first(where: { $0.subcategories.contains(where: { $0.id == subcategory.id }) }) {
                EditCategoryView(category: category, subcategory: subcategory, budgieModel: $budgieModel) {
                    updateScreen()
                }
            }
        }
    }

    private var customNavigationBar: some View {
        ZStack {
            Text("deep pockets")
                .font(.headline)
                .foregroundColor(.primary)
            
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
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(UIColor.systemBackground))
    }

    private var segmentedControlView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BudgetTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 8) {
                            Text(tab.emoji)
                                .font(.system(size: 16))
                            Text(tab.title)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                        }
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(selectedTab == tab ? Color(UIColor.tertiarySystemBackground) : Color.clear)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: selectedTab == tab ? 1 : 0)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 40)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func paycheckTotalView() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Paycheck Total")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: totalPerPaycheckBudget)) ?? "$0")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color(UIColor.systemBackground))

            Divider()

            HStack {
                Text(budgetDeficitOrSurplus >= 0 ? "Per Paycheck Surplus" : "Per Paycheck Deficit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: abs(budgetDeficitOrSurplus))) ?? "$0")
                    .font(.headline)
                    .foregroundColor(budgetDeficitOrSurplus >= 0 ? .green : .red)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

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
                Text("Enhance Budget")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black)
            .clipShape(Capsule())
            .shadow(color: .gray, radius: 2, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
    }

    private func allocationListView() -> some View {
        VStack(spacing: 1) {
            if hasDebt {
                ForEach(selectedCategories.filter { $0.type == .debt }) { category in
                    categoryView(category)
                }
            }
            if hasExpenses {
                ForEach(selectedCategories.filter { $0.type == .need || $0.type == .want }) { category in
                    categoryView(category)
                }
            }
            if hasSavings {
                ForEach(selectedCategories.filter { $0.type == .saving }) { category in
                    categoryView(category)
                }
            }
        }
        .padding(.horizontal)
    }

    private func categoryView(_ category: BudgetCategory) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(category.emoji) \(category.name)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: category.type == .saving ? (category.amount ?? 0) : (allocations[category.id] ?? 0))) ?? "$0")")
                    .font(.headline)
                    .foregroundColor(Color.primary)
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
                if category.type == .saving || category.type == .debt {
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        descriptionView(for: category)
                        if let dueDate = category.dueDate {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            dueDateView(for: dueDate)
                        }
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        editDeleteButtons(for: category)
                    }
                } else if category.type == .need || category.type == .want {
                    expenseCategoryView(for: category)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: expandedCategoryIndex == category.id ? 10 : 5)
                .stroke(Color.gray.opacity(expandedCategoryIndex == category.id ? 0.3 : 0.1), lineWidth: expandedCategoryIndex == category.id ? 1 : 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }

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
                        Text(isEditingItem ? "Done" : "Edit Amount")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
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
                        Text("Delete Category")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
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

    private func updateItemAmount(_ item: Any) {
        let id = (item as? BudgetCategory)?.id ?? (item as? BudgetSubCategory)?.id ?? UUID()
        if let newAmount = editedAmounts[id] {
            if let category = item as? BudgetCategory {
                if let index = selectedCategories.firstIndex(where: { $0.id == category.id }) {
                    selectedCategories[index].amount = newAmount
                }
            } else if let subcategory = item as? BudgetSubCategory {
                allocations[subcategory.id] = newAmount
            }
            calculateBudget()
        }
    }

    private func expenseCategoryView(for category: BudgetCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(category.subcategories.filter { $0.isSelected }) { subcategory in
                subcategoryView(for: subcategory, in: category)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .transition(.opacity)
    }

    private func subcategoryView(for subcategory: BudgetSubCategory, in category: BudgetCategory) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(subcategory.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: allocations[subcategory.id] ?? 0)) ?? "$0")")
                    .font(.subheadline)
                    .foregroundColor(Color.primary)
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
                    descriptionView(for: subcategory)
                        .padding(.top, 8)
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    editDeleteButtons(for: subcategory)
                }
                .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private func deleteItem(_ item: Any) {
        if let category = item as? BudgetCategory {
            deleteCategory(category)
        } else if let subcategory = item as? BudgetSubCategory {
            deleteSubcategory(subcategory)
        }
    }

    private func getItemName(_ item: Any) -> String {
        if let category = item as? BudgetCategory {
            return category.name
        } else if let subcategory = item as? BudgetSubCategory {
            return subcategory.name
        }
        return ""
    }

    private func getItemAmount(_ item: Any) -> Double {
        if let category = item as? BudgetCategory {
            return category.amount ?? 0
        } else if let subcategory = item as? BudgetSubCategory {
            return allocations[subcategory.id] ?? 0
        }
        return 0
    }

    private func deleteCategory(_ category: BudgetCategory) {
        budgieModel.removeCategory(category)
        selectedCategories.removeAll { $0.id == category.id }
        calculateBudget()
    }

    private func deleteSubcategory(_ subcategory: BudgetSubCategory) {
        if let categoryIndex = selectedCategories.firstIndex(where: { $0.subcategories.contains(where: { $0.id == subcategory.id }) }) {
            selectedCategories[categoryIndex].subcategories.removeAll { $0.id == subcategory.id }
            calculateBudget()
        }
    }

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

    private func description(for item: Any) -> String {
        if let category = item as? BudgetCategory {
            return category.description
        } else if let subcategory = item as? BudgetSubCategory {
            return subcategory.description
        }
        return ""
    }

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
        budgieModel.calculateAllocations(selectedCategories: relevantCategories)
        allocations = budgieModel.allocations
    }

    private func updateScreen() {
        calculateBudget()
        selectedCategories = BudgetCategoryStore.shared.categories.filter { $0.isSelected }
    }

    enum BudgetTab: String, CaseIterable {
        case yourBudget
        case perfectBudget
        case affordability

        var title: String {
            switch self {
            case .yourBudget: return "Your Budget"
            case .perfectBudget: return "Perfect Budget"
            case .affordability: return "Affordability"
            }
        }

        var emoji: String {
            switch self {
            case .yourBudget: return "💰"
            case .perfectBudget: return "✨"
            case .affordability: return "🏠"
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

struct DeleteConfirmationAlert: View {
    let itemName: String
    let amount: Double
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Are you sure?")
                .font(.headline)
            Text("Do you want to delete \(itemName)?")
                .multilineTextAlignment(.center)
            Text("$\(String(format: "%.2f", amount)) will be added back into your budget.")
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Button(action: onCancel) {
                    Text("No")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray5))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }

                Button(action: onConfirm) {
                    Text("Yes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
        .frame(width: 300)
        .padding(.horizontal)
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
