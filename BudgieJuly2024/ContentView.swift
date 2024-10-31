import SwiftUI

// MARK: - SectionHeaderView
struct SectionHeaderView: View {
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10, corners: [.topLeft, .topRight])
            Spacer()
        }
        .overlay(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .frame(height: 10)
                .offset(y: 5),
            alignment: .bottom
        )
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

// MARK: - ContentView
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
    @State private var hasBudgetingExperience: Bool
    @State private var categoryToAdd: BudgetCategory?
    @State private var showConfirmation = false
    @State private var viewPeriod: ViewPeriod = .perPaycheck
    @State private var isEditingPaycheck = false
    @State private var editedPaycheckAmount: String = ""
    @State private var isDropdownOpen = false
    @Namespace private var animation
    
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
                
                if showPopup {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                showPopup = false
                            }
                        }
                    
                    EnhanceBudgetSheet(
                        budgieModel: $budgieModel,
                        showPopup: $showPopup,
                        selectedCategories: $selectedCategories
                    )
                    .environmentObject(budgetCategoryStore)
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
                                .background(
                                    Group {
                                        if selectedTab == tab {
                                            LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                                                           startPoint: .topLeading,
                                                           endPoint: .bottomTrailing)
                                        } else {
                                            Color.white
                                        }
                                    }
                                )
                                .foregroundColor(selectedTab == tab ? .white : .primary)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
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
    
    // Updated paycheckTotalView
    private func paycheckTotalView() -> some View {
        VStack(spacing: 0) {
            // Time Period Pills - More subtle design
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
            .padding(.top, 12)
            .padding(.bottom, 12)
            
            Divider()
            
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
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

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
                Text("Edit Budget")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "pencil")
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
    
    // Update allocationListView to use current state
        private func allocationListView() -> some View {
            VStack(spacing: 16) {
                // Existing deficit warning if needed...
                
                // Categories
                VStack(spacing: 0) {
                    // Only show sections if they have selected categories of that type
                    if hasDebt && !selectedCategories.filter({ $0.type == .debt }).isEmpty {
                        sectionView(title: "Debt", color: .red, categories: prioritizedCategories(type: .debt))
                    }
                    if hasExpenses && !selectedCategories.filter({ $0.type == .need || $0.type == .want }).isEmpty {
                        sectionView(title: "Expenses", color: .orange, categories: prioritizedCategories(type: .need))
                    }
                    if hasSavings && !selectedCategories.filter({ $0.type == .saving }).isEmpty {
                        sectionView(title: "Savings", color: .green, categories: prioritizedCategories(type: .saving))
                    }
                }
                
                // Surplus recommendations section...
                if budgetDeficitOrSurplus > 0 {
                    surplusRecommendationsSection
                }
            }
            .padding(.horizontal)
        }

    // New surplus section
    private var surplusRecommendationsSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
                Text("Recommended Categories")
                    .font(.subheadline)
                    .foregroundColor(.green)
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: budgetDeficitOrSurplus)) ?? "$0")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
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
    
private func sectionView(title: String, color: Color, categories: [BudgetCategory]) -> some View {
        VStack(spacing: 0) {
            SectionHeaderView(title: title, color: color)
            VStack(spacing: 8) {
                // Sort categories by priority only if there's a deficit
                let sortedCategories = budgetDeficitOrSurplus < 0
                    ? categories.sorted(by: { $0.priority > $1.priority })
                    : categories
                    
                ForEach(sortedCategories) { category in
                    categoryView(category)
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
                        Text(formatAmount(getAdjustedAmount(allocations[category.id] ?? 0)))
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
                    if let recommendedAmount = budgieModel.recommendedAllocations[subcategory.id] {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommended Amount:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("\(currencyFormatter.string(from: NSNumber(value: recommendedAmount)) ?? "$0")")
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
                .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        .padding(.horizontal, 16)
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
                if let index = selectedCategories.firstIndex(where: { $0.id == category.id }) {
                    selectedCategories[index].amount = newAmount
                }
            } else if let subcategory = item as? BudgetSubCategory {
                allocations[subcategory.id] = newAmount
            }
            calculateBudget()
        }
    }
    
    // MARK: - Expense Category View
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
    
    // MARK: - Delete Item
    private func deleteItem(_ item: Any) {
        if let category = item as? BudgetCategory {
            deleteCategory(category)
        } else if let subcategory = item as? BudgetSubCategory {
            deleteSubcategory(subcategory)
        }
    }
    
    // MARK: - Get Item Name
    private func getItemName(_ item: Any) -> String {
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
        budgieModel.removeCategory(category)
        selectedCategories.removeAll { $0.id == category.id }
        calculateBudget()
    }
    
    // MARK: - Delete Subcategory
    private func deleteSubcategory(_ subcategory: BudgetSubCategory) {
        if let categoryIndex = selectedCategories.firstIndex(where: { $0.subcategories.contains(where: { $0.id == subcategory.id }) }) {
            selectedCategories[categoryIndex].subcategories.removeAll { $0.id == subcategory.id }
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
