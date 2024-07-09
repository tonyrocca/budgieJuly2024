import Foundation

struct BudgetSubCategory: Identifiable {
    let id = UUID()
    var name: String
    var allocationPercentage: Double
    var description: String
    var isSelected: Bool = false
}

struct BudgetCategory: Identifiable {
    let id = UUID()
    var name: String
    var emoji: String
    var allocationPercentage: Double
    var subcategories: [BudgetSubCategory]
    var description: String
}

class BudgetCategoryStore: ObservableObject {
    static let shared = BudgetCategoryStore()

    @Published var categories: [BudgetCategory]

    init() {
        categories = [
            BudgetCategory(
                name: "Housing",
                emoji: "🏠",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Mortgage", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Rent", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Utilities", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "HOA Fee", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Home Maintenance", allocationPercentage: 0.0, description: "")
                ],
                description: "Housing related expenses"
            ),
            BudgetCategory(
                name: "Transportation",
                emoji: "🚗",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Car Payment", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Public Transportation", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Ride Share", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Tolls", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Maintenance", allocationPercentage: 0.0, description: "")
                ],
                description: "Transportation related expenses"
            ),
            BudgetCategory(
                name: "Goals",
                emoji: "🎯",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Emergency Fund", allocationPercentage: 0.0, description: "Savings for emergencies."),
                    BudgetSubCategory(name: "Vacation", allocationPercentage: 0.0, description: "Savings for a vacation."),
                    BudgetSubCategory(name: "New Car", allocationPercentage: 0.0, description: "Savings for a new car.")
                ],
                description: "Savings goals"
            )
        ]
    }

    func addCategory(_ category: BudgetCategory) {
        categories.append(category)
    }

    func deleteCategory(at index: Int) {
        categories.remove(at: index)
    }

    func updateCategory(index: Int, name: String, emoji: String, allocationPercentage: Double, description: String) {
        categories[index].name = name
        categories[index].emoji = emoji
        categories[index].allocationPercentage = allocationPercentage
        categories[index].description = description
    }

    func addSubCategory(to categoryIndex: Int, subcategory: BudgetSubCategory) {
        categories[categoryIndex].subcategories.append(subcategory)
    }

    func deleteSubCategory(from categoryIndex: Int, subcategory: BudgetSubCategory) {
        if let subIndex = categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
            categories[categoryIndex].subcategories.remove(at: subIndex)
        }
    }
}
