import Foundation

struct BudgieModel {
    var paycheckAmount: Double
    var paymentCadence: PaymentCadence = .monthly
    var allocations: [UUID: Double] = [:]

    var sortedAllocations: [(key: UUID, value: Double)] {
        allocations.sorted { $0.value > $1.value }
    }

    mutating func calculateAllocations(selectedCategories: [BudgetCategory]) {
        let monthlyPaycheck = paymentCadence.monthlyEquivalent(from: paycheckAmount)

        allocations.removeAll()

        // Calculate allocations based on 50/30/20 rule
        let needsPercentage = 0.50
        let wantsPercentage = 0.30
        let savingsPercentage = 0.20

        let needsCategories = selectedCategories.filter { $0.type == .need }
        let wantsCategories = selectedCategories.filter { $0.type == .want }
        let savingsCategories = selectedCategories.filter { $0.type == .saving }

        let needsTotalPercentage = needsCategories.reduce(0) { $0 + $1.allocationPercentage }
        let wantsTotalPercentage = wantsCategories.reduce(0) { $0 + $1.allocationPercentage }
        let savingsTotalPercentage = savingsCategories.reduce(0) { $0 + $1.allocationPercentage }

        func allocateBudget(for categories: [BudgetCategory], totalPercentage: Double, totalAllocation: Double) {
            for category in categories {
                let adjustedPercentage = category.allocationPercentage / totalPercentage
                let categoryAllocation = totalAllocation * adjustedPercentage
                allocations[category.id] = categoryAllocation

                let selectedSubcategories = category.subcategories.filter { $0.isSelected }
                let subcategoryTotalPercentage = selectedSubcategories.reduce(0) { $0 + $1.allocationPercentage }

                for subcategory in selectedSubcategories {
                    let subcategoryAdjustedPercentage = subcategory.allocationPercentage / subcategoryTotalPercentage
                    let subcategoryAllocation = categoryAllocation * subcategoryAdjustedPercentage
                    allocations[subcategory.id] = subcategoryAllocation
                }
            }
        }

        allocateBudget(for: needsCategories, totalPercentage: needsTotalPercentage, totalAllocation: monthlyPaycheck * needsPercentage)
        allocateBudget(for: wantsCategories, totalPercentage: wantsTotalPercentage, totalAllocation: monthlyPaycheck * wantsPercentage)
        allocateBudget(for: savingsCategories, totalPercentage: savingsTotalPercentage, totalAllocation: monthlyPaycheck * savingsPercentage)

        // Update the BudgetCategoryStore with the calculated allocations
        for category in selectedCategories {
            if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
                BudgetCategoryStore.shared.updateCategory(index: index, name: category.name, emoji: category.emoji, allocationPercentage: category.allocationPercentage, description: category.description, type: category.type)
            }
        }
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

    mutating func updateCategory(_ category: BudgetCategory, newPercentage: Double) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.updateCategory(index: index, name: category.name, emoji: category.emoji, allocationPercentage: newPercentage, description: category.description, type: category.type)
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories)
    }
}
