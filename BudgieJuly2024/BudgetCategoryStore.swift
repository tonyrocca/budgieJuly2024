import Foundation

public enum CategoryType: String, Codable, Equatable, CaseIterable {
    case debt
    case need
    case want
    case saving
}

struct BudgetSubCategory: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var allocationPercentage: Double
    var description: String
    var isSelected: Bool
    var amount: Double?
    var dueDate: Date?
    var priority: Int

    init(id: UUID = UUID(), name: String, allocationPercentage: Double, description: String, isSelected: Bool = false, amount: Double? = nil, dueDate: Date? = nil, priority: Int) {
        self.id = id
        self.name = name
        self.allocationPercentage = allocationPercentage
        self.description = description
        self.isSelected = isSelected
        self.amount = amount
        self.dueDate = dueDate
        self.priority = priority
    }

    static func == (lhs: BudgetSubCategory, rhs: BudgetSubCategory) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.allocationPercentage == rhs.allocationPercentage &&
               lhs.description == rhs.description &&
               lhs.isSelected == rhs.isSelected &&
               lhs.amount == rhs.amount &&
               lhs.dueDate == rhs.dueDate &&
               lhs.priority == rhs.priority
    }
}

struct BudgetCategory: Identifiable, Codable, Equatable {
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
    var priority: Int

    init(id: UUID = UUID(), name: String, emoji: String, allocationPercentage: Double, subcategories: [BudgetSubCategory], description: String, type: CategoryType, amount: Double? = nil, dueDate: Date? = nil, isSelected: Bool = false, priority: Int) {
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
        self.priority = priority
    }

    static func == (lhs: BudgetCategory, rhs: BudgetCategory) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.emoji == rhs.emoji &&
               lhs.allocationPercentage == rhs.allocationPercentage &&
               lhs.subcategories == rhs.subcategories &&
               lhs.description == rhs.description &&
               lhs.type == rhs.type &&
               lhs.amount == rhs.amount &&
               lhs.dueDate == rhs.dueDate &&
               lhs.isSelected == rhs.isSelected &&
               lhs.priority == rhs.priority
    }
}

class BudgetCategoryStore: ObservableObject {
    static let shared = BudgetCategoryStore()

    @Published var categories: [BudgetCategory]

    init() {
        categories = [
            // Debt Categories (10)
            BudgetCategory(
                name: "Student Loan",
                emoji: "🎓",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Money borrowed to pay for education expenses. Example: Federal student loans.",
                type: .debt,
                priority: 1
            ),
            BudgetCategory(
                name: "Medical Debt",
                emoji: "🏥",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Debt incurred from medical expenses. Example: Hospital bills.",
                type: .debt,
                priority: 1
            ),
            BudgetCategory(
                name: "Credit Card Debt",
                emoji: "💳",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Unpaid balance on credit cards. Example: Purchases made with a credit card.",
                type: .debt,
                priority: 1
            ),
            BudgetCategory(
                name: "Personal Loan",
                emoji: "💰",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Loan taken for personal expenses. Example: Loan from a bank for home improvements.",
                type: .debt,
                priority: 2
            ),
            BudgetCategory(
                name: "Small Business Loan",
                emoji: "🏢",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Loan to start or expand a small business. Example: SBA loans.",
                type: .debt,
                priority: 2
            ),
            BudgetCategory(
                name: "Tax Debt",
                emoji: "💸",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Unpaid taxes owed to the government. Example: Income tax debt.",
                type: .debt,
                priority: 1
            ),
            BudgetCategory(
                name: "Consolidation Loan",
                emoji: "🔗",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Loan taken to consolidate multiple debts. Example: Debt consolidation loan.",
                type: .debt,
                priority: 3
            ),
            BudgetCategory(
                name: "Payday Loan",
                emoji: "🏦",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Short-term loan typically used for urgent expenses. Example: Payday loan.",
                type: .debt,
                priority: 4
            ),
            BudgetCategory(
                name: "Alimony",
                emoji: "💼",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Payments made to a spouse or ex-spouse following a divorce. Example: Alimony payments.",
                type: .debt,
                priority: 2
            ),

            // Expense Categories (10)
            BudgetCategory(
                name: "Housing",
                emoji: "🏠",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Mortgage", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Rent", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Utilities", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Home Maintenance", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Property Tax", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Home Insurance", allocationPercentage: 0.0, description: "", priority: 1)
                ],
                description: "Housing related expenses",
                type: .need,
                priority: 1
            ),
            BudgetCategory(
                name: "Transportation",
                emoji: "🚗",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Car Payment", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Public Transportation", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Ride Share", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Tolls", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Maintenance", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Fuel", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Car Insurance", allocationPercentage: 0.0, description: "", priority: 2)
                ],
                description: "Transportation related expenses",
                type: .need,
                priority: 2
            ),
            BudgetCategory(
                name: "Food",
                emoji: "🍽️",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Groceries", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Dining Out", allocationPercentage: 0.0, description: "", priority: 4),
                    BudgetSubCategory(name: "Snacks", allocationPercentage: 0.0, description: "", priority: 4),
                    BudgetSubCategory(name: "Meal Delivery", allocationPercentage: 0.0, description: "Food delivered to home. Example: UberEats or DoorDash.", priority: 4)
                ],
                description: "Food related expenses",
                type: .need,
                priority: 2
            ),
            BudgetCategory(
                name: "Healthcare",
                emoji: "🩺",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Insurance Premiums", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Doctor Visits", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Medications", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Dental Care", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Vision Care", allocationPercentage: 0.0, description: "", priority: 1)
                ],
                description: "Healthcare related expenses",
                type: .need,
                priority: 2
            ),
            BudgetCategory(
                name: "Utilities",
                emoji: "🔦",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Electricity", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Water", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Gas", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Internet", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Cable", allocationPercentage: 0.0, description: "", priority: 2),
                    BudgetSubCategory(name: "Trash", allocationPercentage: 0.0, description: "", priority: 2)
                ],
                description: "Utility related expenses",
                type: .need,
                priority: 2
            ),
            BudgetCategory(
                name: "Pets",
                emoji: "🐶",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Food", allocationPercentage: 0.0, description: "", priority: 3),
                    BudgetSubCategory(name: "Vet Visits", allocationPercentage: 0.0, description: "", priority: 3),
                    BudgetSubCategory(name: "Medications", allocationPercentage: 0.0, description: "", priority: 1),
                    BudgetSubCategory(name: "Grooming", allocationPercentage: 0.0, description: "", priority: 3),
                    BudgetSubCategory(name: "Toys", allocationPercentage: 0.0, description: "", priority: 3),
                    BudgetSubCategory(name: "Pet Insurance", allocationPercentage: 0.0, description: "", priority: 3)
                ],
                description: "Pet related expenses",
                type: .need,
                priority: 4
            ),
            BudgetCategory(
                name: "Subscriptions",
                emoji: "📺",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Streaming Services", allocationPercentage: 0.0, description: "", priority: 5),
                    BudgetSubCategory(name: "Music Services", allocationPercentage: 0.0, description: "", priority: 5),
                    BudgetSubCategory(name: "Magazines", allocationPercentage: 0.0, description: "", priority: 5),
                    BudgetSubCategory(name: "Apps", allocationPercentage: 0.0, description: "", priority: 5),
                    BudgetSubCategory(name: "News Subscriptions", allocationPercentage: 0.0, description: "", priority: 5)
                ],
                description: "Subscription related expenses",
                type: .want,
                priority: 5
            ),
            BudgetCategory(
                name: "Entertainment",
                emoji: "🎮",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Movies", allocationPercentage: 0.0, description: "", priority: 5),
                    BudgetSubCategory(name: "Games", allocationPercentage: 0.0, description: "", priority: 5),
                    BudgetSubCategory(name: "Concerts", allocationPercentage: 0.0, description: "", priority: 5),
                    BudgetSubCategory(name: "Sports Events", allocationPercentage: 0.0, description: "", priority: 5),
                    BudgetSubCategory(name: "Hobbies", allocationPercentage: 0.0, description: "", priority: 5)
                ],
                description: "Entertainment related expenses",
                type: .want,
                priority: 5
            ),
            BudgetCategory(
                name: "Personal Care",
                emoji: "💅",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Haircuts", allocationPercentage: 0.0, description: "", priority: 4),
                    BudgetSubCategory(name: "Skincare", allocationPercentage: 0.0, description: "", priority: 4),
                    BudgetSubCategory(name: "Cosmetics", allocationPercentage: 0.0, description: "", priority: 4),
                    BudgetSubCategory(name: "Spa Treatments", allocationPercentage: 0.0, description: "", priority: 4),
                    BudgetSubCategory(name: "Gym Membership", allocationPercentage: 0.0, description: "", priority: 4)
                ],
                description: "Personal care related expenses",
                type: .need,
                priority: 4
            ),
            BudgetCategory(
                name: "Education",
                emoji: "📚",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Tuition", allocationPercentage: 0.0, description: "", priority: 3),
                    BudgetSubCategory(name: "Books & Supplies", allocationPercentage: 0.0, description: "", priority: 3),
                    BudgetSubCategory(name: "Online Courses", allocationPercentage: 0.0, description: "", priority: 3),
                    BudgetSubCategory(name: "School Fees", allocationPercentage: 0.0, description: "", priority: 3)
                ],
                description: "Education related expenses",
                type: .need,
                priority: 3
            ),

            // Savings Categories (15)
            BudgetCategory(
                name: "Emergency Fund",
                emoji: "💰",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for unexpected expenses. Example: Medical emergencies or car repairs.",
                type: .saving,
                priority: 1
            ),
            BudgetCategory(
                name: "Vacation",
                emoji: "✈️",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for trips and holidays. Example: Annual family vacation.",
                type: .saving,
                priority: 4
            ),
            BudgetCategory(
                name: "New Car",
                emoji: "🚗",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for purchasing a new vehicle. Example: Down payment for a new car.",
                type: .saving,
                priority: 3
            ),
            BudgetCategory(
                name: "Home Renovation",
                emoji: "🔨",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for home improvement projects. Example: Kitchen remodel or new roof.",
                type: .saving,
                priority: 3
            ),
            BudgetCategory(
                name: "Investment",
                emoji: "📈",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for investment opportunities. Example: Stocks, bonds, or real estate.",
                type: .saving,
                priority: 2
            ),
            BudgetCategory(
                name: "Wedding",
                emoji: "💍",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for wedding expenses. Example: Venue, catering, and attire.",
                type: .saving,
                priority: 3
            ),
            BudgetCategory(
                name: "Education Fund",
                emoji: "🎓",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for educational expenses. Example: College tuition and fees.",
                type: .saving,
                priority: 2
            ),
            BudgetCategory(
                name: "Retirement",
                emoji: "🏖️",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for retirement. Example: 401(k) or IRA contributions.",
                type: .saving,
                priority: 1
            ),
            BudgetCategory(
                name: "House Down Payment",
                emoji: "🏠",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for a down payment on a house. Example: 20% down payment for a new home.",
                type: .saving,
                priority: 2
            ),
            BudgetCategory(
                name: "College Fund",
                emoji: "🎓",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for future college expenses. Example: 529 plan contributions.",
                type: .saving,
                priority: 3
            ),
            BudgetCategory(
                name: "Gadgets",
                emoji: "📱",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for gadgets and electronics. Example: New smartphone or laptop.",
                type: .saving,
                priority: 4
            ),
            BudgetCategory(
                name: "Charity",
                emoji: "🎁",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for charitable donations. Example: Donations to non-profits or causes.",
                type: .saving,
                priority: 4
            ),
            BudgetCategory(
                name: "Business Investment",
                emoji: "🏢",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for business investments. Example: Funding a startup or expanding a business.",
                type: .saving,
                priority: 3
            ),
            BudgetCategory(
                name: "Clothing Fund",
                emoji: "👗",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for clothing and accessories. Example: Seasonal wardrobe updates.",
                type: .saving,
                priority: 4
            )
        ]
    }

    func addCategory(name: String, emoji: String, allocationPercentage: Double, subcategories: [BudgetSubCategory], description: String, type: CategoryType, amount: Double? = nil, dueDate: Date? = nil, isSelected: Bool = false, priority: Int? = nil) {
        let category = BudgetCategory(name: name, emoji: emoji, allocationPercentage: allocationPercentage, subcategories: subcategories, description: description, type: type, amount: amount, dueDate: dueDate, isSelected: isSelected, priority: priority ?? 0)
        categories.append(category)
    }

    func deleteCategory(at index: Int) {
        categories.remove(at: index)
    }

    func updateCategory(index: Int, name: String, emoji: String, allocationPercentage: Double, description: String, type: CategoryType, priority: Int) {
        categories[index].name = name
        categories[index].emoji = emoji
        categories[index].allocationPercentage = allocationPercentage
        categories[index].description = description
        categories[index].type = type
        categories[index].priority = priority
    }

    func addSubcategoryToCategory(categoryID: UUID, name: String, allocationPercentage: Double, description: String, isSelected: Bool = false, amount: Double? = nil, dueDate: Date? = nil, priority: Int) {
        let subcategory = BudgetSubCategory(name: name, allocationPercentage: allocationPercentage, description: description, isSelected: isSelected, amount: amount, dueDate: dueDate, priority: priority)
        
        if let index = categories.firstIndex(where: { $0.id == categoryID }) {
            categories[index].subcategories.append(subcategory)
        }
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

    func updateCategoryAmount(_ category: BudgetCategory, amount: Double) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].amount = amount
        }
    }
}
