import SwiftUI

// MARK: - BudgetRecommendation Model
struct BudgetRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let category: BudgetCategory
    let subcategory: BudgetSubCategory?
    let currentAmount: Double
    let recommendedAmount: Double
    let reason: String
}

// MARK: - RecommendationType Enum
enum RecommendationType {
    case updateAmount
    case addCategory
    case removeCategory
}

// MARK: - EnhanceBudgetSheet
struct EnhanceBudgetSheet: View {
    @Binding var budgieModel: BudgieModel
    @Binding var showPopup: Bool
    @Binding var selectedCategories: [BudgetCategory]
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var currentTab: RecommendationType = .updateAmount

    let screenHeight = UIScreen.main.bounds.height
    let sheetHeight: CGFloat = UIScreen.main.bounds.height * 0.75
    
    private var recommendations: [BudgetRecommendation] {
        switch currentTab {
        case .updateAmount:
            return getUpdateRecommendations()
        case .addCategory:
            return getAddRecommendations()
        case .removeCategory:
            return getRemoveRecommendations()
        }
    }
    
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
                
                // Tab Switcher
                Picker("Recommendation Type", selection: $currentTab) {
                    Text("Update").tag(RecommendationType.updateAmount)
                    Text("Add").tag(RecommendationType.addCategory)
                    Text("Remove").tag(RecommendationType.removeCategory)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
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
                
                // Action Button
                Button(action: {
                    withAnimation {
                        showPopup = false
                    }
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
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
    
    // MARK: - Recommendation Generators
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
    
    private func getAddRecommendations() -> [BudgetRecommendation] {
        let criticalCategories = ["Emergency Fund", "Retirement"]
        let missingCriticalCategories = budgetCategoryStore.categories.filter { category in
            criticalCategories.contains(category.name) && !selectedCategories.contains(where: { $0.id == category.id })
        }
        
        return missingCriticalCategories.map { category in
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
    
    // MARK: - Apply Recommendation
    private func applyRecommendation(_ recommendation: BudgetRecommendation) {
        switch recommendation.type {
        case .updateAmount:
            if let index = selectedCategories.firstIndex(where: { $0.id == recommendation.category.id }) {
                selectedCategories[index].amount = recommendation.recommendedAmount
                budgieModel.updateCategory(recommendation.category, newAmount: recommendation.recommendedAmount)
            }
        case .addCategory:
            if !selectedCategories.contains(where: { $0.id == recommendation.category.id }) {
                var newCategory = recommendation.category
                newCategory.amount = recommendation.recommendedAmount
                newCategory.isSelected = true
                selectedCategories.append(newCategory)
                budgieModel.addCategory(newCategory)
            }
        case .removeCategory:
            if let index = selectedCategories.firstIndex(where: { $0.id == recommendation.category.id }) {
                let removedCategory = selectedCategories.remove(at: index)
                budgieModel.removeCategory(removedCategory)
            }
        }
    }
}

// MARK: - RecommendationRow
struct RecommendationRow: View {
    let recommendation: BudgetRecommendation
    let onApply: () -> Void
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                
                if recommendation.type == .updateAmount {
                    Text(differenceText(current: recommendation.currentAmount, recommended: recommendation.recommendedAmount))
                        .font(.caption)
                        .foregroundColor(recommendation.currentAmount < recommendation.recommendedAmount ? .green : .red)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
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
        return currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func differenceText(current: Double, recommended: Double) -> String {
        let difference = recommended - current
        let sign = difference >= 0 ? "+" : "-"
        return "\(sign)\(formatCurrency(abs(difference)))"
    }
}

// MARK: - RoundedCorner Shape for Specific Corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - View Extension for Specific Corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
