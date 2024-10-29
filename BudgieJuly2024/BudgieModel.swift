import Foundation
import Combine

class BudgieModel: ObservableObject {
    @Published var paycheckAmount: Double
    @Published var paymentCadence: PaymentCadence = .monthly
    @Published var allocations: [UUID: Double] = [:]
    @Published var perfectAllocations: [UUID: Double] = [:]
    @Published var recommendedAllocations: [UUID: Double] = [:]
    
    var budgetDeficitOrSurplus: Double {
        paycheckAmount - allocations.values.reduce(0, +)
    }
    
    init(paycheckAmount: Double) {
        self.paycheckAmount = paycheckAmount
    }
    
    // MARK: - Allocation Calculations
    
    func calculateAllocations(selectedCategories: [BudgetCategory]) {
        allocations.removeAll()
        
        for category in selectedCategories {
            switch category.type {
            case .debt:
                if let amount = category.amount, let dueDate = category.dueDate {
                    let monthlyAllocation = calculateMonthlyDebtAllocation(totalAmount: amount, dueDate: dueDate)
                    allocations[category.id] = adjustAllocationForPaymentCadence(monthlyAllocation)
                }
            case .saving:
                allocations[category.id] = category.amount ?? 0
            default:
                var categoryAllocation: Double = 0
                for subcategory in category.subcategories.filter({ $0.isSelected }) {
                    let subcategoryAmount = subcategory.amount ?? 0
                    allocations[subcategory.id] = subcategoryAmount
                    categoryAllocation += subcategoryAmount
                }
                allocations[category.id] = categoryAllocation
            }
        }
    }
    
    func calculateRecommendedAllocations(selectedCategories: [BudgetCategory]) {
        recommendedAllocations.removeAll()
        let monthlyIncome = adjustAmountForPaymentCadence(paycheckAmount)
        
        for category in selectedCategories {
            switch category.type {
            case .need, .want:
                let recommendedAmount = calculateRecommendedAmount(for: category, monthlyIncome: monthlyIncome)
                recommendedAllocations[category.id] = recommendedAmount
                
                for subcategory in category.subcategories where subcategory.isSelected {
                    let subcategoryRecommendedAmount = recommendedAmount * (subcategory.allocationPercentage / 100)
                    recommendedAllocations[subcategory.id] = subcategoryRecommendedAmount
                }
            case .saving:
                let recommendedAmount = calculateRecommendedSavingsAmount(for: category.name, monthlyIncome: monthlyIncome)
                recommendedAllocations[category.id] = recommendedAmount
            default:
                break
            }
        }
    }
    
    func calculatePerfectBudget(selectedCategories: [BudgetCategory]) {
        perfectAllocations.removeAll()
        var remainingAmount = paycheckAmount
        
        // Handle debt categories first (keep them unchanged)
        for category in selectedCategories where category.type == .debt {
            perfectAllocations[category.id] = category.amount ?? 0
            remainingAmount -= category.amount ?? 0
        }
        
        // Define ideal percentages for main categories
        let idealPercentages: [CategoryType: Double] = [
            .need: 0.50,
            .want: 0.30,
            .saving: 0.20
        ]
        
        // Calculate and allocate for main categories
        for (type, percentage) in idealPercentages {
            let typeCategories = selectedCategories.filter { $0.type == type }
            guard !typeCategories.isEmpty else { continue }
            
            let typeAllocation = remainingAmount * percentage
            
            for category in typeCategories {
                switch type {
                case .saving:
                    // For saving categories, use a specific calculation
                    let savingsAmount = calculateRecommendedSavingsAmount(for: category.name, monthlyIncome: paycheckAmount)
                    perfectAllocations[category.id] = savingsAmount
                case .need, .want:
                    // For needs and wants, distribute evenly among categories
                    let categoryAllocation = typeAllocation / Double(typeCategories.count)
                    perfectAllocations[category.id] = categoryAllocation
                    
                    // Distribute among subcategories
                    let selectedSubcategories = category.subcategories.filter { $0.isSelected }
                    guard !selectedSubcategories.isEmpty else { continue }
                    
                    let subcategoryAllocation = categoryAllocation / Double(selectedSubcategories.count)
                    for subcategory in selectedSubcategories {
                        perfectAllocations[subcategory.id] = subcategoryAllocation
                    }
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateRecommendedAmount(for category: BudgetCategory, monthlyIncome: Double) -> Double {
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
        
        return monthlyIncome * (recommendedPercentages[category.name] ?? 0.05)
    }
    
    private func calculateRecommendedSavingsAmount(for categoryName: String, monthlyIncome: Double) -> Double {
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
        
        return monthlyIncome * (savingsPercentages[categoryName] ?? 0.05)
    }
    
    private func calculateMonthlyDebtAllocation(totalAmount: Double, dueDate: Date) -> Double {
        let currentDate = Date()
        let calendar = Calendar.current
        let monthsUntilDue = calendar.dateComponents([.month], from: currentDate, to: dueDate).month ?? 1
        return totalAmount / Double(max(1, monthsUntilDue))
    }
    
    func adjustAmountForPaymentCadence(_ amount: Double) -> Double {
        switch paymentCadence {
        case .weekly:
            return amount * 52 / 12
        case .biWeekly:
            return amount * 26 / 12
        case .semiMonthly:
            return amount * 24 / 12
        case .monthly:
            return amount
        }
    }
    
    private func adjustAllocationForPaymentCadence(_ monthlyAllocation: Double) -> Double {
        switch paymentCadence {
        case .weekly:
            return monthlyAllocation * 12 / 52
        case .biWeekly:
            return monthlyAllocation * 12 / 26
        case .monthly:
            return monthlyAllocation
        case .semiMonthly:
            return monthlyAllocation * 12 / 24
        }
    }
    
    // MARK: - Category Management
    
    func updateCategory(_ category: BudgetCategory, newAmount: Double) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.categories[index].amount = newAmount
            allocations[category.id] = newAmount
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected })
        calculateRecommendedAllocations(selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected })
        calculatePerfectBudget(selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected })
    }
    
    func updateSubcategory(category: BudgetCategory, subcategory: BudgetSubCategory, newAmount: Double) {
        if let categoryIndex = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }),
           let subIndex = BudgetCategoryStore.shared.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
            
            BudgetCategoryStore.shared.categories[categoryIndex].subcategories[subIndex].amount = newAmount
            
            let newCategoryTotal = BudgetCategoryStore.shared.categories[categoryIndex].subcategories.reduce(0) { $0 + ($1.amount ?? 0) }
            BudgetCategoryStore.shared.categories[categoryIndex].amount = newCategoryTotal
            
            allocations[subcategory.id] = newAmount
            allocations[category.id] = newCategoryTotal
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected })
        calculateRecommendedAllocations(selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected })
        calculatePerfectBudget(selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected })
    }
    
    func addCategory(_ category: BudgetCategory) {
        BudgetCategoryStore.shared.addCategory(
            name: category.name,
            emoji: category.emoji,
            allocationPercentage: category.allocationPercentage,
            subcategories: category.subcategories,
            description: category.description,
            type: category.type,
            amount: category.amount,
            dueDate: category.dueDate,
            isSelected: category.isSelected,
            priority: category.priority
        )
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
        calculateRecommendedAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
        calculatePerfectBudget(selectedCategories: BudgetCategoryStore.shared.categories)
    }
    
    func removeCategory(_ category: BudgetCategory) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.deleteCategory(at: index)
        }
        allocations.removeValue(forKey: category.id)
        recommendedAllocations.removeValue(forKey: category.id)
        perfectAllocations.removeValue(forKey: category.id)
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
        calculateRecommendedAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
        calculatePerfectBudget(selectedCategories: BudgetCategoryStore.shared.categories)
    }
    
    // MARK: - Additional Calculations
    
    func calculateMonthlyDebtAllocation(from startDate: Date, to endDate: Date, amount: Double) -> Double {
        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: startDate, to: endDate).month ?? 1
        return amount / Double(max(1, months))
    }
    
    func calculateSavingsAmount(for categoryName: String, monthlyPaycheck: Double) -> Double {
        let savingsPercentages: [String: Double] = [
            "Emergency Fund": 0.10,
            "Vacation": 0.05,
            "New Car": 0.05,
            "Home Renovation": 0.07,
            "Investment": 0.10,
            "Wedding": 0.05,
            "Education Fund": 0.05,
            "Retirement": 0.10,
            "House Down Payment": 0.10,
            "College Fund": 0.10,
            "Emergency Savings": 0.10,
            "Travel Fund": 0.05,
            "Gadgets": 0.05,
            "Fitness": 0.05,
            "Charity": 0.05,
            "Business Investment": 0.10,
            "Clothing Fund": 0.05
        ]
        
        return monthlyPaycheck * (savingsPercentages[categoryName] ?? 0.05)
    }
    
    func generateRecommendations(forSurplus surplus: Bool, selectedCategories: [BudgetCategory]) -> [BudgetCategory] {
        if surplus {
            return BudgetCategoryStore.shared.categories.filter { category in
                !selectedCategories.contains { $0.id == category.id }
            }
        } else {
            return selectedCategories.sorted { (a, b) -> Bool in
                if a.priority != b.priority {
                    return a.priority < b.priority
                } else {
                    let aAmount = allocations[a.id] ?? 0
                    let bAmount = allocations[b.id] ?? 0
                    return (aAmount / (a.amount ?? 1)) > (bAmount / (b.amount ?? 1))
                }
            }
        }
    }
}
