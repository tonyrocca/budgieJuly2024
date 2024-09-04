import SwiftUI

struct BudgetRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let category: String
    let amount: Double?
    let reason: String
    
    var title: String {
        switch type {
        case .addCategory:
            return "Add \(category)"
        case .removeCategory:
            return "Remove \(category)"
        case .increaseAllocation:
            return "Increase \(category) allocation"
        case .decreaseAllocation:
            return "Decrease \(category) allocation"
        }
    }
    
    var actionText: String {
        switch type {
        case .addCategory:
            return "Add Category"
        case .removeCategory:
            return "Remove Category"
        case .increaseAllocation:
            return "Increase Allocation"
        case .decreaseAllocation:
            return "Decrease Allocation"
        }
    }
}

enum RecommendationType {
    case addCategory
    case removeCategory
    case increaseAllocation
    case decreaseAllocation
}

struct EnhanceBudgetSheet: View {
    @Binding var budgieModel: BudgieModel
    @Binding var showPopup: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    @State private var recommendations: [BudgetRecommendation] = []
    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    let screenHeight = UIScreen.main.bounds.height
    let sheetHeight: CGFloat = UIScreen.main.bounds.height * 0.75 // 75% of screen height
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag Indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary)
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                // Header
                HStack {
                    Text("Enhance Your Budget")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: { showPopup = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Surplus/Deficit Info
                surplusDeficitView
                
                // Recommendations List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(recommendations) { recommendation in
                            RecommendationRow(recommendation: recommendation) {
                                applyRecommendation(recommendation)
                            }
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
        .onAppear {
            generateRecommendations()
        }
    }
    
    private var surplusDeficitView: some View {
        HStack {
            Text(budgieModel.budgetDeficitOrSurplus >= 0 ? "Current Surplus:" : "Current Deficit:")
                .fontWeight(.medium)
            Spacer()
            Text(formatCurrency(budgieModel.budgetDeficitOrSurplus))
                .fontWeight(.bold)
                .foregroundColor(budgieModel.budgetDeficitOrSurplus >= 0 ? .green : .red)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private func generateRecommendations() {
        recommendations = []
        
        // Check for emergency savings
        if !budgetCategoryStore.categories.contains(where: { $0.name == "Emergency Fund" && $0.isSelected }) {
            recommendations.append(BudgetRecommendation(type: .addCategory, category: "Emergency Fund", amount: nil, reason: "It's important to have an emergency fund for unexpected expenses."))
        }
        
        // Compare with perfect budget allocations
        for category in budgetCategoryStore.categories where category.isSelected {
            let currentAllocation = budgieModel.allocations[category.id] ?? 0
            let perfectAllocation = budgieModel.perfectAllocations[category.id] ?? 0
            
            if currentAllocation < perfectAllocation * 0.8 {
                recommendations.append(BudgetRecommendation(type: .increaseAllocation, category: category.name, amount: perfectAllocation - currentAllocation, reason: "You're underfunding this category based on recommended allocations."))
            } else if currentAllocation > perfectAllocation * 1.2 {
                recommendations.append(BudgetRecommendation(type: .decreaseAllocation, category: category.name, amount: currentAllocation - perfectAllocation, reason: "You might be overspending in this category based on recommended allocations."))
            }
        }
        
        // Suggest new categories if there's a surplus
        if budgieModel.budgetDeficitOrSurplus > 0 {
            let unselectedCategories = budgetCategoryStore.categories.filter { !$0.isSelected }
            for category in unselectedCategories.prefix(3) {
                recommendations.append(BudgetRecommendation(type: .addCategory, category: category.name, amount: nil, reason: "Consider adding this category to your budget for a more comprehensive financial plan."))
            }
        }
        
        // Suggest removing categories if there's a deficit
        if budgieModel.budgetDeficitOrSurplus < 0 {
            let nonEssentialCategories = budgetCategoryStore.categories.filter { $0.isSelected && $0.type == .want }
            for category in nonEssentialCategories.prefix(3) {
                recommendations.append(BudgetRecommendation(type: .removeCategory, category: category.name, amount: nil, reason: "Consider removing or reducing this non-essential category to balance your budget."))
            }
        }
    }
    
    private func applyRecommendation(_ recommendation: BudgetRecommendation) {
        switch recommendation.type {
        case .addCategory:
            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.name == recommendation.category }) {
                budgetCategoryStore.categories[index].isSelected = true
            }
        case .removeCategory:
            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.name == recommendation.category }) {
                budgetCategoryStore.categories[index].isSelected = false
            }
        case .increaseAllocation, .decreaseAllocation:
            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.name == recommendation.category }),
               let amount = recommendation.amount {
                let currentAmount = budgieModel.allocations[budgetCategoryStore.categories[index].id] ?? 0
                let newAmount = recommendation.type == .increaseAllocation ? currentAmount + amount : currentAmount - amount
                budgieModel.updateCategory(budgetCategoryStore.categories[index], newAmount: newAmount)
            }
        }
        
        // Recalculate budget and regenerate recommendations
        budgieModel.calculateAllocations(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected })
        budgieModel.calculatePerfectBudget(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected })
        generateRecommendations()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }
}

struct RecommendationRow: View {
    let recommendation: BudgetRecommendation
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recommendation.title)
                .font(.headline)
            Text(recommendation.reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let amount = recommendation.amount {
                Text(formatCurrency(amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Button(action: onApply) {
                Text(recommendation.actionText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
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
