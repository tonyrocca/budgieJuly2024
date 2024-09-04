import SwiftUI

struct BudgetRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let category: BudgetCategory
    let subcategory: BudgetSubCategory?
    let currentAmount: Double
    let recommendedAmount: Double
    let reason: String
}

enum RecommendationType {
    case updateAmount
    case addCategory
    case removeCategory
}

struct EnhanceBudgetSheet: View {
    @Binding var budgieModel: BudgieModel
    @Binding var showPopup: Bool
    @Binding var selectedCategories: [BudgetCategory]
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    let screenHeight = UIScreen.main.bounds.height
    let sheetHeight: CGFloat = UIScreen.main.bounds.height * 0.75
    
    private let lightGrayColor = Color(UIColor.systemGray6)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag Indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary)
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                // Header
                Text("Enhance Your Budget")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        updateAmountsSection()
                        
                        if budgieModel.budgetDeficitOrSurplus > 0 {
                            addMissingCriticalCategorySection()
                        } else if budgieModel.budgetDeficitOrSurplus < 0 {
                            removeCategorySection()
                        }
                    }
                    .padding()
                }
            }
            .frame(height: sheetHeight)
            .background(Color(UIColor.systemBackground))
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
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private func updateAmountsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Update Amounts")
                .font(.headline)
            
            ForEach(getUpdateRecommendations()) { recommendation in
                RecommendationRow(recommendation: recommendation) {
                    applyRecommendation(recommendation)
                }
            }
        }
    }
    
    private func addMissingCriticalCategorySection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Critical Category")
                .font(.headline)
            
            if let recommendation = getMissingCriticalCategoryRecommendation() {
                RecommendationRow(recommendation: recommendation) {
                    applyRecommendation(recommendation)
                }
            } else {
                Text("No critical categories missing")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func removeCategorySection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reduce Expenses")
                .font(.headline)
            
            ForEach(getRemoveRecommendations()) { recommendation in
                RecommendationRow(recommendation: recommendation) {
                    applyRecommendation(recommendation)
                }
            }
        }
    }
    
    private func getUpdateRecommendations() -> [BudgetRecommendation] {
        return selectedCategories.compactMap { category in
            let currentAmount = budgieModel.allocations[category.id] ?? 0
            let recommendedAmount = budgieModel.perfectAllocations[category.id] ?? 0
            
            if abs(currentAmount - recommendedAmount) > max(currentAmount * 0.1, 10) { // Only recommend if change is >10% or >$10
                return BudgetRecommendation(
                    type: .updateAmount,
                    category: category,
                    subcategory: nil,
                    currentAmount: currentAmount,
                    recommendedAmount: recommendedAmount,
                    reason: "Adjust to optimize your budget"
                )
            }
            return nil
        }
    }
    
    private func getMissingCriticalCategoryRecommendation() -> BudgetRecommendation? {
        let criticalCategories = ["Emergency Fund", "Retirement"]
        let missingCriticalCategory = budgetCategoryStore.categories.first { category in
            criticalCategories.contains(category.name) && !selectedCategories.contains(where: { $0.id == category.id })
        }
        
        if let category = missingCriticalCategory {
            let recommendedAmount = budgieModel.calculateSavingsAmount(for: category.name, monthlyPaycheck: budgieModel.paycheckAmount)
            return BudgetRecommendation(
                type: .addCategory,
                category: category,
                subcategory: nil,
                currentAmount: 0,
                recommendedAmount: recommendedAmount,
                reason: "Add this important category to your budget"
            )
        }
        return nil
    }
    
    private func getRemoveRecommendations() -> [BudgetRecommendation] {
        let sortedWants = selectedCategories.filter { $0.type == .want }
            .sorted { (budgieModel.allocations[$0.id] ?? 0) > (budgieModel.allocations[$1.id] ?? 0) }
        
        return sortedWants.prefix(3).map { category in
            BudgetRecommendation(
                type: .removeCategory,
                category: category,
                subcategory: nil,
                currentAmount: budgieModel.allocations[category.id] ?? 0,
                recommendedAmount: 0,
                reason: "Consider reducing this expense to balance your budget"
            )
        }
    }
    
    private func applyRecommendation(_ recommendation: BudgetRecommendation) {
        switch recommendation.type {
        case .updateAmount:
            if selectedCategories.contains(where: { $0.id == recommendation.category.id }) {
                budgieModel.updateCategory(recommendation.category, newAmount: recommendation.recommendedAmount)
            }
        case .addCategory:
            if !selectedCategories.contains(where: { $0.id == recommendation.category.id }) {
                budgieModel.addCategory(recommendation.category)
                selectedCategories.append(recommendation.category)
            }
        case .removeCategory:
            if selectedCategories.contains(where: { $0.id == recommendation.category.id }) {
                budgieModel.removeCategory(recommendation.category)
                selectedCategories.removeAll { $0.id == recommendation.category.id }
            }
        }
    }
}

struct RecommendationRow: View {
    let recommendation: BudgetRecommendation
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(recommendation.category.emoji) \(recommendation.category.name)")
                    .font(.headline)
                Spacer()
                Button(action: onApply) {
                    Text(actionText(for: recommendation.type))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Text(recommendation.reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current: \(formatCurrency(recommendation.currentAmount))")
                    Text("Recommended: \(formatCurrency(recommendation.recommendedAmount))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func actionText(for type: RecommendationType) -> String {
        switch type {
        case .updateAmount:
            return "Update"
        case .addCategory:
            return "Add"
        case .removeCategory:
            return "Remove"
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }
}

// Helper extension for custom corner radius
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
