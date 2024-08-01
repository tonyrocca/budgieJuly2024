import Foundation

enum CategoryType: String, Codable {
    case need
    case want
    case saving
    case debt
}

struct BudgetSubCategory: Identifiable, Codable {
    var id: UUID
    var name: String
    var allocationPercentage: Double
    var description: String
    var isSelected: Bool
    var amount: Double?
    var dueDate: Date?

    init(id: UUID = UUID(), name: String, allocationPercentage: Double, description: String, isSelected: Bool = false, amount: Double? = nil, dueDate: Date? = nil) {
        self.id = id
        self.name = name
        self.allocationPercentage = allocationPercentage
        self.description = description
        self.isSelected = isSelected
        self.amount = amount
        self.dueDate = dueDate
    }
}

struct BudgetCategory: Identifiable, Codable {
    var id: UUID
    var name: String
    var emoji: String
    var allocationPercentage: Double
    var subcategories: [BudgetSubCategory]
    var description: String
    var type: CategoryType
    var amount: Double?
    var dueDate: Date?
    var isSelected: Bool

    init(id: UUID = UUID(), name: String, emoji: String, allocationPercentage: Double, subcategories: [BudgetSubCategory], description: String, type: CategoryType, amount: Double? = nil, dueDate: Date? = nil, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.allocationPercentage = allocationPercentage
        self.subcategories = subcategories
        self.description = description
        self.type = type
        self.amount = amount
        self.dueDate = dueDate
        self.isSelected = isSelected
    }
}

class BudgetCategoryStore: ObservableObject {
    static let shared = BudgetCategoryStore()

    @Published var categories: [BudgetCategory]

    init() {
        categories = [
            // Debt Categories
            BudgetCategory(
                name: "Student Loan",
                emoji: "🎓",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Student loan debt",
                type: .debt
            ),
            BudgetCategory(
                name: "Medical Debt",
                emoji: "🏥",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Medical debt",
                type: .debt
            ),
            BudgetCategory(
                name: "Credit Card Debt",
                emoji: "💳",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Credit card debt",
                type: .debt
            ),
            BudgetCategory(
                name: "Personal Loan",
                emoji: "💰",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Personal loan debt",
                type: .debt
            ),
            BudgetCategory(
                name: "Auto Loan",
                emoji: "🚗",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Auto loan debt",
                type: .debt
            ),
            BudgetCategory(
                name: "Mortgage",
                emoji: "🏠",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Mortgage debt",
                type: .debt
            ),
            // Expense Categories
            BudgetCategory(
                name: "Housing",
                emoji: "🏠",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Mortgage", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Rent", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Utilities", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "HOA Fee", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Home Maintenance", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Property Tax", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Home Insurance", allocationPercentage: 0.0, description: "")
                ],
                description: "Housing related expenses",
                type: .need
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
                    BudgetSubCategory(name: "Maintenance", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Fuel", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Car Insurance", allocationPercentage: 0.0, description: "")
                ],
                description: "Transportation related expenses",
                type: .need
            ),
            BudgetCategory(
                name: "Food",
                emoji: "🍽️",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Groceries", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Dining Out", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Snacks", allocationPercentage: 0.0, description: "")
                ],
                description: "Food related expenses",
                type: .need
            ),
            BudgetCategory(
                name: "Healthcare",
                emoji: "🩺",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Insurance Premiums", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Doctor Visits", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Medications", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Dental Care", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Vision Care", allocationPercentage: 0.0, description: "")
                ],
                description: "Healthcare related expenses",
                type: .need
            ),
            BudgetCategory(
                name: "Entertainment",
                emoji: "🎬",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Streaming Services", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Movies", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Concerts", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Games", allocationPercentage: 0.0, description: "")
                ],
                description: "Entertainment related expenses",
                type: .want
            ),
            BudgetCategory(
                name: "Utilities",
                emoji: "💡",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Electricity", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Water", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Gas", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Internet", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Cable", allocationPercentage: 0.0, description: ""),
                    BudgetSubCategory(name: "Trash", allocationPercentage: 0.0, description: "")
                ],
                description: "Utility related expenses",
                type: .need
            ),
            // Savings Categories
            BudgetCategory(
                name: "Emergency Fund",
                emoji: "💰",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for emergencies",
                type: .saving
            ),
            BudgetCategory(
                name: "Vacation",
                emoji: "✈️",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for a vacation",
                type: .saving
            ),
            BudgetCategory(
                name: "New Car",
                emoji: "🚗",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for a new car",
                type: .saving
            ),
            BudgetCategory(
                name: "Home Renovation",
                emoji: "🔨",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for home renovation",
                type: .saving
            ),
            BudgetCategory(
                name: "Investment",
                emoji: "📈",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for investments",
                type: .saving
            ),
            BudgetCategory(
                name: "Wedding",
                emoji: "💍",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for a wedding",
                type: .saving
            ),
            BudgetCategory(
                name: "Education Fund",
                emoji: "🎓",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for education",
                type: .saving
            ),
            BudgetCategory(
                name: "Retirement",
                emoji: "🏖️",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for retirement",
                type: .saving
            ),
            BudgetCategory(
                name: "House Down Payment",
                emoji: "🏠",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for a house down payment",
                type: .saving
            ),
            BudgetCategory(
                name: "College Fund",
                emoji: "🎓",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for college",
                type: .saving
            )
        ]
    }

    func addCategory(_ category: BudgetCategory) {
        categories.append(category)
    }

    func deleteCategory(at index: Int) {
        categories.remove(at: index)
    }

    func updateCategory(index: Int, name: String, emoji: String, allocationPercentage: Double, description: String, type: CategoryType) {
        categories[index].name = name
        categories[index].emoji = emoji
        categories[index].allocationPercentage = allocationPercentage
        categories[index].description = description
        categories[index].type = type
    }

    func addSubCategory(to categoryIndex: Int, subcategory: BudgetSubCategory) {
        categories[categoryIndex].subcategories.append(subcategory)
    }

    func deleteSubCategory(from categoryIndex: Int, subcategory: BudgetSubCategory) {
        if let subIndex = categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
            categories[categoryIndex].subcategories.remove(at: subIndex)
        }
    }

    func updateCategoryAmountAndDueDate(categoryId: UUID, amount: Double, dueDate: Date) {
        if let index = categories.firstIndex(where: { $0.id == categoryId }) {
            categories[index].amount = amount
            categories[index].dueDate = dueDate
        }
    }

    func addSubcategoryToCategory(_ subcategory: BudgetSubCategory, categoryID: UUID) {
        if let index = categories.firstIndex(where: { $0.id == categoryID }) {
            categories[index].subcategories.append(subcategory)
        }
    }
}
