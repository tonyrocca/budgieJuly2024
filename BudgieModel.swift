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
            case .need, .want:
                // For expenses, ignore category amount and only use subcategory amounts
                let selectedSubcategories = category.subcategories.filter { $0.isSelected }
                let categoryTotal = selectedSubcategories.reduce(0.0) { total, subcategory in
                    let subcategoryAmount = subcategory.amount ?? 0
                    allocations[subcategory.id] = subcategoryAmount
                    return total + subcategoryAmount
                }
                // Category total is ONLY the sum of subcategories
                allocations[category.id] = categoryTotal
                
            case .debt:
                if let amount = category.amount, let dueDate = category.dueDate {
                    let monthlyAllocation = calculateMonthlyDebtAllocation(totalAmount: amount, dueDate: dueDate)
                    allocations[category.id] = adjustAllocationForPaymentCadence(monthlyAllocation)
                }
                
            case .saving:
                allocations[category.id] = category.amount ?? 0
            }
        }
    }
    
    func calculateRecommendedAllocations(selectedCategories: [BudgetCategory]) {
        recommendedAllocations.removeAll()
        let monthlyIncome = adjustAmountForPaymentCadence(paycheckAmount)
        
        for category in selectedCategories {
            switch category.type {
            case .need, .want:
                // Get the appropriate category limit
                let categoryLimit = getCategoryLimit(for: category.name)
                let maxMonthlyForCategory = monthlyIncome * categoryLimit.max
                
                // For expenses, calculate subcategory recommendations
                for subcategory in category.subcategories where subcategory.isSelected {
                    let subcategoryPercentage = getSubcategoryPercentage(for: subcategory.name, in: category.name)
                    
                    // Calculate monthly amount then convert to per-paycheck
                    let monthlyAmount = maxMonthlyForCategory * subcategoryPercentage
                    let perPaycheckAmount = convertMonthlyToPaycheckAmount(monthlyAmount)
                    
                    recommendedAllocations[subcategory.id] = perPaycheckAmount
                }
                
            case .saving:
                let recommendedAmount = calculateRecommendedSavingsAmount(for: category.name, monthlyIncome: monthlyIncome)
                let perPaycheckAmount = convertMonthlyToPaycheckAmount(recommendedAmount)
                recommendedAllocations[category.id] = perPaycheckAmount
                
            case .debt:
                // Handle debt separately since it's based on total amount and due date
                break
            }
        }
    }
    
    private func getCategoryLimit(for categoryName: String) -> (min: Double, max: Double) {
        switch categoryName {
        case "Housing":
            return (min: 0.25, max: 0.28) // Max 28% of income
        case "Transportation":
            return (min: 0.10, max: 0.12) // Max 12% of income
        case "Food":
            return (min: 0.10, max: 0.12) // Max 12% of income
        case "Utilities":
            return (min: 0.05, max: 0.08) // Max 8% of income
        case "Healthcare":
            return (min: 0.05, max: 0.08) // Max 8% of income
        case "Personal Care":
            return (min: 0.02, max: 0.03) // Max 3% of income
        case "Entertainment":
            return (min: 0.02, max: 0.05) // Max 5% of income
        default:
            return (min: 0.02, max: 0.05) // Default 5% max
        }
    }
    
    private func getSubcategoryPercentage(for subcategoryName: String, in categoryName: String) -> Double {
        switch categoryName {
        case "Housing":
            switch subcategoryName {
            case "Mortgage", "Rent": return 0.70  // 70% of housing budget
            case "Utilities": return 0.15         // 15% of housing budget
            case "Home Maintenance": return 0.10   // 10% of housing budget
            case "Property Tax": return 0.03       // 3% of housing budget
            case "Home Insurance": return 0.02     // 2% of housing budget
            default: return 0.10
            }
            
        case "Transportation":
            switch subcategoryName {
            case "Car Payment": return 0.50       // 50% of transportation budget
            case "Fuel": return 0.20              // 20% of transportation budget
            case "Maintenance": return 0.15       // 15% of transportation budget
            case "Car Insurance": return 0.10     // 10% of transportation budget
            case "Public Transportation": return 0.05 // 5% of transportation budget
            case "Ride Share": return 0.03        // 3% of transportation budget
            case "Tolls": return 0.02             // 2% of transportation budget
            default: return 0.10
            }
            
        case "Food":
            switch subcategoryName {
            case "Groceries": return 0.70         // 70% of food budget
            case "Dining Out": return 0.15        // 15% of food budget
            case "Meal Delivery": return 0.10     // 10% of food budget
            case "Snacks": return 0.05            // 5% of food budget
            default: return 0.10
            }
            
        case "Healthcare":
            switch subcategoryName {
            case "Insurance Premiums": return 0.50 // 50% of healthcare budget
            case "Doctor Visits": return 0.20      // 20% of healthcare budget
            case "Medications": return 0.15        // 15% of healthcare budget
            case "Dental Care": return 0.10        // 10% of healthcare budget
            case "Vision Care": return 0.05        // 5% of healthcare budget
            default: return 0.10
            }
            
        case "Utilities":
            switch subcategoryName {
            case "Electricity": return 0.35        // 35% of utilities budget
            case "Water": return 0.15              // 15% of utilities budget
            case "Gas": return 0.15                // 15% of utilities budget
            case "Internet": return 0.20           // 20% of utilities budget
            case "Cable": return 0.10              // 10% of utilities budget
            case "Trash": return 0.05              // 5% of utilities budget
            default: return 0.10
            }
            
        case "Pets":
            switch subcategoryName {
            case "Food": return 0.40               // 40% of pet budget
            case "Vet Visits": return 0.30         // 30% of pet budget
            case "Medications": return 0.15        // 15% of pet budget
            case "Grooming": return 0.05           // 5% of pet budget
            case "Toys": return 0.05               // 5% of pet budget
            case "Pet Insurance": return 0.05      // 5% of pet budget
            default: return 0.10
            }
            
        case "Subscriptions":
            switch subcategoryName {
            case "Streaming Services": return 0.40  // 40% of subscription budget
            case "Music Services": return 0.20      // 20% of subscription budget
            case "Apps": return 0.15                // 15% of subscription budget
            case "News Subscriptions": return 0.15  // 15% of subscription budget
            case "Magazines": return 0.10           // 10% of subscription budget
            default: return 0.10
            }
            
        case "Entertainment":
            switch subcategoryName {
            case "Movies": return 0.20              // 20% of entertainment budget
            case "Games": return 0.20               // 20% of entertainment budget
            case "Concerts": return 0.25            // 25% of entertainment budget
            case "Sports Events": return 0.20       // 20% of entertainment budget
            case "Hobbies": return 0.15            // 15% of entertainment budget
            default: return 0.10
            }
            
        case "Personal Care":
            switch subcategoryName {
            case "Haircuts": return 0.30            // 30% of personal care budget
            case "Skincare": return 0.20            // 20% of personal care budget
            case "Cosmetics": return 0.20           // 20% of personal care budget
            case "Spa Treatments": return 0.15      // 15% of personal care budget
            case "Gym Membership": return 0.15      // 15% of personal care budget
            default: return 0.10
            }
            
        case "Education":
            switch subcategoryName {
            case "Tuition": return 0.70             // 70% of education budget
            case "Books & Supplies": return 0.15    // 15% of education budget
            case "Online Courses": return 0.10      // 10% of education budget
            case "School Fees": return 0.05         // 5% of education budget
            default: return 0.10
            }
            
        default:
            // If no specific mapping exists, distribute evenly
            return 1.0 / 3.0  // Assumes roughly 3 subcategories on average
        }
    }
    
    private func convertMonthlyToPaycheckAmount(_ monthlyAmount: Double) -> Double {
        switch paymentCadence {
        case .weekly:
            return monthlyAmount / 4.33 // More accurate weekly division
        case .biWeekly:
            return monthlyAmount / 2.167 // More accurate bi-weekly division
        case .semiMonthly:
            return monthlyAmount / 2.0
        case .monthly:
            return monthlyAmount
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
            
            // Only update the subcategory amount
            BudgetCategoryStore.shared.categories[categoryIndex].subcategories[subIndex].amount = newAmount
            
            // Recalculate the total based only on subcategories
            let newCategoryTotal = BudgetCategoryStore.shared.categories[categoryIndex].subcategories
                .filter { $0.isSelected }
                .reduce(0.0) { $0 + ($1.amount ?? 0) }
            
            // Update allocations
            allocations[subcategory.id] = newAmount
            allocations[category.id] = newCategoryTotal
        }
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
