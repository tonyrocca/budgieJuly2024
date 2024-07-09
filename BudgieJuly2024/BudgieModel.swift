import Foundation

struct BudgieModel {
    var paycheckAmount: Double
    var paymentCadence: PaymentCadence = .monthly
    var allocations: [String: Double] = [:]

    // Add this to return sorted allocations
    var sortedAllocations: [(key: String, value: Double)] {
        allocations.sorted { $0.value > $1.value }
    }

    mutating func calculateAllocations() {
        let currentCategories = BudgetCategoryStore.shared.categories

        // Calculate the total percentage of the current categories
        let totalPercentage = currentCategories.reduce(0) { $0 + $1.allocationPercentage }

        // Adjust the allocations based on the current categories
        let monthlyPaycheck = paymentCadence.monthlyEquivalent(from: paycheckAmount)

        allocations.removeAll()

        for category in currentCategories {
            let adjustedPercentage = category.allocationPercentage / totalPercentage
            let categoryAllocation = monthlyPaycheck * adjustedPercentage
            allocations[category.name] = categoryAllocation

            for subcategory in category.subcategories where subcategory.isSelected {
                let subcategoryAllocation = categoryAllocation * subcategory.allocationPercentage / category.allocationPercentage
                allocations[subcategory.name] = subcategoryAllocation
            }
        }
    }

    // Add a category and recalculate allocations
    mutating func addCategory(_ category: BudgetCategory) {
        BudgetCategoryStore.shared.addCategory(category)
        calculateAllocations()
    }

    // Remove a category and recalculate allocations
    mutating func removeCategory(_ category: BudgetCategory) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.deleteCategory(at: index)
        }
        calculateAllocations()
    }

    // Update a category and recalculate allocations
    mutating func updateCategory(_ category: BudgetCategory, newPercentage: Double) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.updateCategory(index: index, name: category.name, emoji: category.emoji, allocationPercentage: newPercentage, description: category.description)
        }
        calculateAllocations()
    }
}
