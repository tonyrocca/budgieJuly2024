import Foundation

struct BudgieModel {
    var paycheckAmount: Double
    var paymentCadence: PaymentCadence = .monthly
    var allocations: [UUID: Double] = [:]

    mutating func calculateAllocations(selectedCategories: [BudgetCategory]) {
        allocations.removeAll()

        for category in selectedCategories {
            if category.type == .saving || category.type == .debt {
                allocations[category.id] = category.amount ?? 0
            } else {
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

    mutating func updateCategory(_ category: BudgetCategory, newAmount: Double) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.categories[index].amount = newAmount
            allocations[category.id] = newAmount
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected })
    }

    mutating func updateSubcategory(category: BudgetCategory, subcategory: BudgetSubCategory, newAmount: Double) {
        if let categoryIndex = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }),
           let subIndex = BudgetCategoryStore.shared.categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
            
            BudgetCategoryStore.shared.categories[categoryIndex].subcategories[subIndex].amount = newAmount
            
            let newCategoryTotal = BudgetCategoryStore.shared.categories[categoryIndex].subcategories.reduce(0) { $0 + ($1.amount ?? 0) }
            BudgetCategoryStore.shared.categories[categoryIndex].amount = newCategoryTotal
            
            allocations[subcategory.id] = newAmount
            allocations[category.id] = newCategoryTotal
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories.filter { $0.isSelected })
    }

    mutating func addCategory(_ category: BudgetCategory) {
        BudgetCategoryStore.shared.addCategory(category)
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
    }

    mutating func removeCategory(_ category: BudgetCategory) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.deleteCategory(at: index)
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
    }

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
                let aAmount = allocations[a.id] ?? 0
                let bAmount = allocations[b.id] ?? 0
                return (aAmount / (a.amount ?? 1)) > (bAmount / (b.amount ?? 1))
            }
        }
    }
}
