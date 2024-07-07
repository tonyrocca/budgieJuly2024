import Foundation

struct BudgetSubCategory: Identifiable {
    var id: UUID = UUID()
    var name: String
    var allocationPercentage: Double
    var description: String
}

struct BudgetCategory: Identifiable {
    var id: UUID = UUID()
    var name: String
    var emoji: String
    var allocationPercentage: Double
    var description: String
    var subcategories: [BudgetSubCategory] = []
}

class BudgetCategoryStore: ObservableObject {
    @Published var categories: [BudgetCategory] = [
        BudgetCategory(name: "Housing", emoji: "🏠", allocationPercentage: 0.30, description: "Expenses related to housing, such as rent or mortgage payments.", subcategories: [
            BudgetSubCategory(name: "Mortgage", allocationPercentage: 0.20, description: "Monthly mortgage payment"),
            BudgetSubCategory(name: "Rent", allocationPercentage: 0.10, description: "Monthly rent payment"),
            BudgetSubCategory(name: "Utilities", allocationPercentage: 0.05, description: "Monthly utilities payment"),
            BudgetSubCategory(name: "HOA Fee", allocationPercentage: 0.03, description: "Monthly HOA fee"),
            BudgetSubCategory(name: "Home Maintenance", allocationPercentage: 0.02, description: "Costs for maintaining and repairing your home")
        ]),
        BudgetCategory(name: "Transportation", emoji: "🚗", allocationPercentage: 0.10, description: "Expenses for car payments, gas, or public transportation.", subcategories: [
            BudgetSubCategory(name: "Car Payment", allocationPercentage: 0.05, description: "Monthly car payment"),
            BudgetSubCategory(name: "Public Transportation", allocationPercentage: 0.02, description: "Monthly public transportation costs"),
            BudgetSubCategory(name: "Ride Share", allocationPercentage: 0.01, description: "Monthly ride share costs"),
            BudgetSubCategory(name: "Tolls", allocationPercentage: 0.01, description: "Monthly tolls"),
            BudgetSubCategory(name: "Maintenance", allocationPercentage: 0.01, description: "Monthly car maintenance costs")
        ])
        // Add more categories and subcategories as needed
    ]

    static let shared = BudgetCategoryStore()

    private init() {}

    func addCategory(_ category: BudgetCategory) {
        categories.append(category)
    }

    func deleteCategory(at index: Int) {
        categories.remove(at: index)
    }

    func updateCategory(index: Int, name: String, emoji: String, allocationPercentage: Double, description: String) {
        categories[index] = BudgetCategory(name: name, emoji: emoji, allocationPercentage: allocationPercentage, description: description, subcategories: categories[index].subcategories)
    }
}
