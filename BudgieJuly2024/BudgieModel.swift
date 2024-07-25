import Foundation

struct BudgieModel {
    var paycheckAmount: Double
    var paymentCadence: PaymentCadence = .monthly
    var allocations: [UUID: Double] = [:]

    // Add this to return sorted allocations
    var sortedAllocations: [(key: UUID, value: Double)] {
        allocations.sorted { $0.value > $1.value }
    }

    mutating func calculateAllocations(selectedCategories: [BudgetCategory]) {
        let monthlyPaycheck = paymentCadence.monthlyEquivalent(from: paycheckAmount)

        allocations.removeAll()

        for category in selectedCategories {
            var categoryTotal: Double = 0.0
            let subTotalPercentage = category.subcategories.filter { $0.isSelected }.reduce(0, { $0 + $1.allocationPercentage })
            
            for subcategory in category.subcategories.filter({ $0.isSelected }) {
                if let amount = subcategory.amount {
                    allocations[subcategory.id] = amount
                    categoryTotal += amount
                } else {
                    let adjustedPercentage = subcategory.allocationPercentage / subTotalPercentage
                    let subcategoryAllocation = monthlyPaycheck * adjustedPercentage
                    allocations[subcategory.id] = subcategoryAllocation
                    categoryTotal += subcategoryAllocation
                }
            }

            if category.type == .debt, let amount = category.amount, let dueDate = category.dueDate {
                let monthlyDebtAllocation = calculateMonthlyDebtAllocation(from: Date(), to: dueDate, amount: amount)
                allocations[category.id] = monthlyDebtAllocation
            } else {
                allocations[category.id] = categoryTotal
            }
        }
    }

    // Add a category and recalculate allocations
    mutating func addCategory(_ category: BudgetCategory) {
        BudgetCategoryStore.shared.addCategory(category)
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
    }

    // Remove a category and recalculate allocations
    mutating func removeCategory(_ category: BudgetCategory) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.deleteCategory(at: index)
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
    }

    // Update a category and recalculate allocations
    mutating func updateCategory(_ category: BudgetCategory, newPercentage: Double) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.updateCategory(index: index, name: category.name, emoji: category.emoji, allocationPercentage: newPercentage, description: category.description, type: category.type)
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
    }

    func calculateMonthlyDebtAllocation(from startDate: Date, to endDate: Date, amount: Double) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        let numberOfMonths = components.month ?? 0
        return numberOfMonths > 0 ? amount / Double(numberOfMonths) : amount
    }
}
