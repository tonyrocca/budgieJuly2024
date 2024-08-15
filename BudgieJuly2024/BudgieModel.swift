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

        for category in selectedCategories {
            var categoryAllocation: Double = 0

            if category.type == .saving {
                categoryAllocation = category.amount ?? 0
            } else {
                for subcategory in category.subcategories.filter({ $0.isSelected }) {
                    if let subcategoryAmount = subcategory.amount {
                        allocations[subcategory.id] = subcategoryAmount
                        categoryAllocation += subcategoryAmount
                    } else {
                        allocations[subcategory.id] = 0
                    }
                }
            }

            if categoryAllocation > 0 {
                allocations[category.id] = categoryAllocation
            } else if category.type == .debt, let amount = category.amount, let dueDate = category.dueDate {
                let monthlyDebtAllocation = calculateMonthlyDebtAllocation(from: Date(), to: dueDate, amount: amount)
                allocations[category.id] = monthlyDebtAllocation
            } else if category.type == .saving {
                let savingsAmount = calculateSavingsAmount(for: category.name, monthlyPaycheck: monthlyPaycheck)
                allocations[category.id] = savingsAmount
            } else {
                allocations[category.id] = 0
            }
        }
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
            // Recommend categories not in the current budget
            return BudgetCategoryStore.shared.categories.filter { category in
                !selectedCategories.contains { $0.id == category.id }
            }
        } else {
            // Recommend categories to reduce or remove based on their delta from the recommended amount
            return selectedCategories.sorted { (a, b) -> Bool in
                let aAmount = allocations[a.id] ?? 0
                let bAmount = allocations[b.id] ?? 0
                return (aAmount / (a.amount ?? 1)) > (bAmount / (b.amount ?? 1))
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
