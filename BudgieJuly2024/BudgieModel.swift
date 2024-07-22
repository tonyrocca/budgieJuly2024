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
        let totalPercentage = selectedCategories.reduce(0) { $0 + $1.allocationPercentage }
        let monthlyPaycheck = paymentCadence.monthlyEquivalent(from: paycheckAmount)

        allocations.removeAll()

        for category in selectedCategories {
            let adjustedPercentage = category.allocationPercentage / totalPercentage
            let categoryAllocation = monthlyPaycheck * adjustedPercentage
            allocations[category.id] = categoryAllocation

            let subTotalPercentage = category.subcategories.filter { $0.isSelected }.reduce(0, { $0 + $1.allocationPercentage })
            
            for subcategory in category.subcategories.filter({ $0.isSelected }) {
                let subAdjustedPercentage = subcategory.allocationPercentage / subTotalPercentage
                allocations[subcategory.id] = categoryAllocation * subAdjustedPercentage
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
}
