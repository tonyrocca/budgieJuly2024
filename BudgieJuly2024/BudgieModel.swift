import Foundation

struct BudgieModel {
    var paycheckAmount: Double
    var paymentCadence: PaymentCadence = .monthly
    var allocations: [UUID: Double] = [:]

    var sortedAllocations: [(key: UUID, value: Double)] {
        allocations.sorted { $0.value > $1.value }
    }

    mutating func calculateAllocations(selectedCategories: [BudgetCategory], isPerPaycheck: Bool) {
        let monthlyPaycheck = paymentCadence.monthlyEquivalent(from: paycheckAmount)
        let conversionFactor = isPerPaycheck ? 1.0 / paymentCadence.numberOfPaychecksPerMonth : 1.0

        allocations.removeAll()

        for category in selectedCategories {
            var categoryTotal: Double = 0.0
            let subTotalPercentage = category.subcategories.filter { $0.isSelected }.reduce(0, { $0 + $1.allocationPercentage })

            for subcategory in category.subcategories.filter({ $0.isSelected }) {
                if let amount = subcategory.amount {
                    let adjustedAmount = amount * conversionFactor
                    allocations[subcategory.id] = adjustedAmount
                    categoryTotal += adjustedAmount
                } else {
                    let adjustedPercentage = subcategory.allocationPercentage / subTotalPercentage
                    let subcategoryAllocation = monthlyPaycheck * adjustedPercentage
                    allocations[subcategory.id] = subcategoryAllocation
                    categoryTotal += subcategoryAllocation
                }
            }

            if category.type == .debt {
                if let amount = category.amount, let dueDate = category.dueDate {
                    let monthlyDebtAllocation = calculateMonthlyDebtAllocation(from: Date(), to: dueDate, amount: amount)
                    allocations[category.id] = monthlyDebtAllocation * conversionFactor
                }
            } else {
                allocations[category.id] = categoryTotal
            }
        }
    }

    mutating func addCategory(_ category: BudgetCategory) {
        BudgetCategoryStore.shared.addCategory(category)
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories, isPerPaycheck: false)
    }

    mutating func removeCategory(_ category: BudgetCategory) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.deleteCategory(at: index)
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories, isPerPaycheck: false)
    }

    mutating func updateCategory(_ category: BudgetCategory, newPercentage: Double) {
        if let index = BudgetCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) {
            BudgetCategoryStore.shared.updateCategory(index: index, name: category.name, emoji: category.emoji, allocationPercentage: newPercentage, description: category.description, type: category.type)
        }
        calculateAllocations(selectedCategories: BudgetCategoryStore.shared.categories, isPerPaycheck: false)
    }

    func calculateMonthlyDebtAllocation(from startDate: Date, to endDate: Date, amount: Double) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        let numberOfMonths = components.month ?? 0
        return numberOfMonths > 0 ? amount / Double(numberOfMonths) : amount
    }
}
