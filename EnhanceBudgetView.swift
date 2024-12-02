import SwiftUI

struct EnhanceBudgetSheet: View {
    @Binding var budgieModel: BudgieModel
    @Binding var showPopup: Bool
    @Binding var selectedCategories: [BudgetCategory]
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    @State private var showConfirmation = false
    @State private var categoryToAdd: BudgetCategory?
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            // Header
            VStack(spacing: 4) {
                Text("Recommendations")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(customGreen)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Essential Missing Categories
                    if let missingEssentials = getMissingEssentialCategories() {
                        RecommendationSection(
                            title: "Essential Categories",
                            categories: missingEssentials,
                            type: .add,
                            budgieModel: budgieModel
                        ) { category in
                            categoryToAdd = category
                            showConfirmation = true
                        }
                    }
                    
                    // Adjustment Recommendations
                    if let adjustments = getCategoryAdjustments() {
                        RecommendationSection(
                            title: "Suggested Adjustments",
                            categories: adjustments,
                            type: .adjust,
                            budgieModel: budgieModel
                        ) { category in
                            // Handle adjustment
                        }
                    }
                    
                    // Reduction Suggestions (only if in deficit)
                    if budgieModel.budgetDeficitOrSurplus < 0,
                       let reductions = getReductionSuggestions() {
                        RecommendationSection(
                            title: "Suggested Reductions",
                            categories: reductions,
                            type: .reduce,
                            budgieModel: budgieModel
                        ) { category in
                            // Handle reduction
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .alert(isPresented: $showConfirmation) {
            confirmationAlert()
        }
    }
    
    // Helper struct to represent a recommendation
    struct CategoryRecommendation: Identifiable {
        let id: UUID
        let category: BudgetCategory
        let currentAmount: Double?
        let recommendedAmount: Double
        let reason: String
        let priority: Int
    }
    
    // Recommendation type enum
    enum RecommendationType {
        case add
        case adjust
        case reduce
    }
    
    // MARK: - Helper Functions
    
    private func getMissingEssentialCategories() -> [CategoryRecommendation]? {
        let savingsCategories = [
            (
                name: "Emergency Fund",
                emoji: "🏦",
                reason: "Having 3-6 months of expenses saved is crucial for financial security. This fund helps protect you from unexpected costs and provides peace of mind.",
                priority: 1,
                recommendedPercentage: 0.10
            ),
            (
                name: "Retirement",
                emoji: "🏖️",
                reason: "Starting retirement savings early is key to long-term financial success. Experts recommend saving 15% of your income for retirement.",
                priority: 1,
                recommendedPercentage: 0.15
            ),
            (
                name: "House Down Payment",
                emoji: "🏠",
                reason: "Saving for a home down payment can help you build equity and reduce monthly payments. Aim for 20% of your target home price.",
                priority: 2,
                recommendedPercentage: 0.10
            ),
            (
                name: "Investment",
                emoji: "📈",
                reason: "Building an investment portfolio helps grow your wealth over time through compound interest and market returns.",
                priority: 2,
                recommendedPercentage: 0.08
            )
        ]
        
        let missing = savingsCategories.compactMap { category in
            if !selectedCategories.contains(where: { $0.name == category.name }) {
                let recommendedAmount = budgieModel.paycheckAmount * category.recommendedPercentage
                let newCategory = BudgetCategory(
                    name: category.name,
                    emoji: category.emoji,
                    allocationPercentage: category.recommendedPercentage,
                    subcategories: [],
                    description: category.reason,
                    type: .saving,
                    priority: category.priority
                )
                return CategoryRecommendation(
                    id: UUID(),
                    category: newCategory,
                    currentAmount: nil,
                    recommendedAmount: recommendedAmount,
                    reason: category.reason,
                    priority: category.priority
                )
            }
            return nil
        }
        
        return missing.isEmpty ? nil : missing
    }
    
    private func getCategoryAdjustments() -> [CategoryRecommendation]? {
        let adjustments = selectedCategories.compactMap { category in
            let currentAmount = budgieModel.allocations[category.id] ?? 0
            let recommendedAmount = calculateRecommendedAmount(for: category)
            
            // Check if adjustment is needed (more than 20% difference)
            let difference = abs(currentAmount - recommendedAmount) / recommendedAmount
            if difference > 0.2 {
                return CategoryRecommendation(
                    id: UUID(),
                    category: category,
                    currentAmount: currentAmount,
                    recommendedAmount: recommendedAmount,
                    reason: currentAmount < recommendedAmount ?
                        "Consider increasing this category" :
                        "This category might be over-allocated",
                    priority: category.priority
                )
            }
            return nil
        }
        
        return adjustments.isEmpty ? nil : adjustments
    }
    
    private func getReductionSuggestions() -> [CategoryRecommendation]? {
        let nonEssential = selectedCategories
            .filter { $0.type == .want && $0.priority > 3 }
            .map { category in
                let currentAmount = budgieModel.allocations[category.id] ?? 0
                let recommendedAmount = calculateRecommendedAmount(for: category) * 0.7 // Suggest 30% reduction
                return CategoryRecommendation(
                    id: UUID(),
                    category: category,
                    currentAmount: currentAmount,
                    recommendedAmount: recommendedAmount,
                    reason: "Non-essential expense that could be reduced",
                    priority: category.priority
                )
            }
        
        return nonEssential.isEmpty ? nil : nonEssential
    }
    
    private func confirmationAlert() -> Alert {
        let impact = calculateBudgetImpact()
        return Alert(
            title: Text("Add Category"),
            message: Text("Adding '\(categoryToAdd?.name ?? "")' will \(impact.change) your budget by \(formatCurrency(abs(impact.amount))).\nYour new \(impact.newTotal >= 0 ? "surplus" : "deficit") will be \(formatCurrency(abs(impact.newTotal)))."),
            primaryButton: .default(Text("Add")) {
                if let category = categoryToAdd {
                    addCategoryToBudget(category)
                }
            },
            secondaryButton: .cancel()
        )
    }
    
    private func calculateBudgetImpact() -> (change: String, amount: Double, newTotal: Double) {
        let currentTotal = budgieModel.allocations.values.reduce(0, +)
        let newAmount = categoryToAdd.map { calculateRecommendedAmount(for: $0) } ?? 0
        let newTotal = budgieModel.paycheckAmount - (currentTotal + newAmount)
        let change = newAmount >= 0 ? "decrease" : "increase"
        return (change, newAmount, newTotal)
    }
    
    private func calculateRecommendedAmount(for category: BudgetCategory) -> Double {
        // Use existing recommended percentages from BudgieModel
        let perPaycheckIncome = budgieModel.paycheckAmount
        
        let recommendedPercentages: [String: Double] = [
            "Housing": 0.30,
            "Transportation": 0.15,
            "Food": 0.12,
            "Healthcare": 0.10,
            "Utilities": 0.08,
            "Emergency Fund": 0.10,
            "Retirement": 0.15
        ]
        
        return perPaycheckIncome * (recommendedPercentages[category.name] ?? 0.05)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
            budgetCategoryStore.addCategory(
                name: category.name,
                emoji: category.emoji,
                allocationPercentage: category.allocationPercentage,
                subcategories: category.subcategories,
                description: category.description,
                type: category.type,
                amount: recommendedAmount,
                dueDate: category.dueDate,
                isSelected: true,
                priority: category.priority
            )
        } else if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
            budgetCategoryStore.categories[index] = newCategory
        }
        
        // Update selectedCategories
        if !selectedCategories.contains(where: { $0.id == newCategory.id }) {
            selectedCategories.append(newCategory)
        }
        
        // Update allocations
        budgieModel.allocations[newCategory.id] = recommendedAmount
        budgieModel.recommendedAllocations[newCategory.id] = recommendedAmount
        budgieModel.updateCategory(newCategory, newAmount: recommendedAmount)
        
        // Close the popup
        showPopup = false
    }
}

// MARK: - RecommendationSection

struct RecommendationSection: View {
    let title: String
    let categories: [EnhanceBudgetSheet.CategoryRecommendation]
    let type: EnhanceBudgetSheet.RecommendationType
    let budgieModel: BudgieModel
    let onAction: (BudgetCategory) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)
            
            VStack(spacing: 8) {
                ForEach(categories) { recommendation in
                    RecommendationRow(
                        recommendation: recommendation,
                        type: type,
                        onAction: onAction
                    )
                }
            }
        }
    }
}

// MARK: - RecommendationRow

struct RecommendationRow: View {
    let recommendation: EnhanceBudgetSheet.CategoryRecommendation
    let type: EnhanceBudgetSheet.RecommendationType
    let onAction: (BudgetCategory) -> Void
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    
    // Currency formatter
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private func formatCurrency(_ amount: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(recommendation.category.emoji)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.category.name)
                        .font(.headline)
                    
                    Text("Recommended: \(formatCurrency(recommendation.recommendedAmount))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(recommendation.recommendedAmount))
                        .font(.headline)
                    Text("/paycheck")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(recommendation.reason)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            
            Button(action: { onAction(recommendation.category) }) {
                HStack {
                    Image(systemName: type == .add ? "plus" : (type == .adjust ? "arrow.up.arrow.down" : "minus"))
                        .font(.system(size: 12, weight: .bold))
                    Text(type == .add ? "Add to Budget" : (type == .adjust ? "Adjust Amount" : "Reduce Amount"))
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(type == .add ? customGreen : (type == .adjust ? Color.blue : Color.red))
                .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Notification Extension (if needed)

extension Notification.Name {
    static let budgetUpdated = Notification.Name("budgetUpdated")
}
