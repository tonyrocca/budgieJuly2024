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
                description: "Money borrowed to pay for education expenses. Example: Federal student loans.",
                type: .debt
            ),
            BudgetCategory(
                name: "Medical Debt",
                emoji: "🏥",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Debt incurred from medical expenses. Example: Hospital bills.",
                type: .debt
            ),
            BudgetCategory(
                name: "Credit Card Debt",
                emoji: "💳",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Unpaid balance on credit cards. Example: Purchases made with a credit card.",
                type: .debt
            ),
            BudgetCategory(
                name: "Personal Loan",
                emoji: "💰",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Loan taken for personal expenses. Example: Loan from a bank for home improvements.",
                type: .debt
            ),
            BudgetCategory(
                name: "Small Business Loan",
                emoji: "🏢",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Loan to start or expand a small business. Example: SBA loans.",
                type: .debt
            ),
            BudgetCategory(
                name: "Tax Debt",
                emoji: "💸",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Unpaid taxes owed to the government. Example: Income tax debt.",
                type: .debt
            ),
            // Expense Categories
            BudgetCategory(
                name: "Housing",
                emoji: "🏠",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Rent", allocationPercentage: 0.0, description: "Monthly payment for living space. Example: Apartment rent."),
                    BudgetSubCategory(name: "Utilities", allocationPercentage: 0.0, description: "Basic services for the home. Example: Electricity and water bills."),
                    BudgetSubCategory(name: "HOA Fee", allocationPercentage: 0.0, description: "Monthly or annual fee for homeowners association. Example: Fees for condo amenities."),
                    BudgetSubCategory(name: "Home Maintenance", allocationPercentage: 0.0, description: "Upkeep and repairs for the home. Example: Fixing a leaky roof."),
                    BudgetSubCategory(name: "Property Tax", allocationPercentage: 0.0, description: "Annual tax on property ownership. Example: County property tax."),
                    BudgetSubCategory(name: "Home Insurance", allocationPercentage: 0.0, description: "Insurance coverage for the home. Example: Homeowners insurance policy.")
                ],
                description: "Housing related expenses",
                type: .need
            ),
            BudgetCategory(
                name: "Transportation",
                emoji: "🚗",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Car Payment", allocationPercentage: 0.0, description: "Monthly payment for car loan. Example: Loan payment for a new car."),
                    BudgetSubCategory(name: "Public Transportation", allocationPercentage: 0.0, description: "Cost of using public transit. Example: Monthly metro pass."),
                    BudgetSubCategory(name: "Ride Share", allocationPercentage: 0.0, description: "Expenses for ride-sharing services. Example: Uber or Lyft rides."),
                    BudgetSubCategory(name: "Tolls", allocationPercentage: 0.0, description: "Fees for using toll roads. Example: Toll charges on highways."),
                    BudgetSubCategory(name: "Maintenance", allocationPercentage: 0.0, description: "Upkeep for the vehicle. Example: Oil changes and tire rotations."),
                    BudgetSubCategory(name: "Fuel", allocationPercentage: 0.0, description: "Cost of gasoline. Example: Monthly fuel expenses."),
                    BudgetSubCategory(name: "Car Insurance", allocationPercentage: 0.0, description: "Insurance coverage for the vehicle. Example: Auto insurance policy.")
                ],
                description: "Transportation related expenses",
                type: .need
            ),
            BudgetCategory(
                name: "Food",
                emoji: "🍽️",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Groceries", allocationPercentage: 0.0, description: "Food and supplies for home. Example: Weekly grocery shopping."),
                    BudgetSubCategory(name: "Dining Out", allocationPercentage: 0.0, description: "Meals eaten at restaurants. Example: Dinner at a local restaurant."),
                    BudgetSubCategory(name: "Snacks", allocationPercentage: 0.0, description: "Quick bites and snacks. Example: Afternoon snacks and treats.")
                ],
                description: "Food related expenses",
                type: .need
            ),
            BudgetCategory(
                name: "Healthcare",
                emoji: "🩺",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Insurance Premiums", allocationPercentage: 0.0, description: "Monthly cost for health insurance. Example: Employer health insurance premium."),
                    BudgetSubCategory(name: "Doctor Visits", allocationPercentage: 0.0, description: "Cost of medical consultations. Example: Annual check-up with a doctor."),
                    BudgetSubCategory(name: "Medications", allocationPercentage: 0.0, description: "Prescription and over-the-counter drugs. Example: Monthly prescription refills."),
                    BudgetSubCategory(name: "Dental Care", allocationPercentage: 0.0, description: "Expenses for dental health. Example: Bi-annual dental cleaning."),
                    BudgetSubCategory(name: "Vision Care", allocationPercentage: 0.0, description: "Cost of eye care and glasses. Example: Annual eye exam and new glasses.")
                ],
                description: "Healthcare related expenses",
                type: .need
            ),
            BudgetCategory(
                name: "Utilities",
                emoji: "💡",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Electricity", allocationPercentage: 0.0, description: "Monthly electric bill. Example: Power bill for home."),
                    BudgetSubCategory(name: "Water", allocationPercentage: 0.0, description: "Monthly water bill. Example: City water services."),
                    BudgetSubCategory(name: "Gas", allocationPercentage: 0.0, description: "Monthly gas bill. Example: Natural gas heating."),
                    BudgetSubCategory(name: "Internet", allocationPercentage: 0.0, description: "Monthly cost for internet. Example: High-speed internet service."),
                    BudgetSubCategory(name: "Cable", allocationPercentage: 0.0, description: "Monthly cable TV bill. Example: Cable television subscription."),
                    BudgetSubCategory(name: "Trash", allocationPercentage: 0.0, description: "Monthly trash collection fee. Example: Waste management services.")
                ],
                description: "Utility related expenses",
                type: .need
            ),
            BudgetCategory(
                name: "Pets",
                emoji: "🐶",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Food", allocationPercentage: 0.0, description: "Monthly cost of pet food. Example: Dog food and treats."),
                    BudgetSubCategory(name: "Vet Visits", allocationPercentage: 0.0, description: "Cost of veterinary care. Example: Annual vet check-up."),
                    BudgetSubCategory(name: "Medications", allocationPercentage: 0.0, description: "Cost of pet medications. Example: Monthly flea treatment."),
                    BudgetSubCategory(name: "Grooming", allocationPercentage: 0.0, description: "Expenses for pet grooming. Example: Dog grooming services."),
                    BudgetSubCategory(name: "Toys", allocationPercentage: 0.0, description: "Cost of pet toys and accessories. Example: New toys and bedding."),
                    BudgetSubCategory(name: "Pet Insurance", allocationPercentage: 0.0, description: "Monthly cost for pet insurance. Example: Insurance policy for pets.")
                ],
                description: "Pet related expenses",
                type: .need
            ),
            BudgetCategory(
                name: "Subscriptions",
                emoji: "📺",
                allocationPercentage: 0.0,
                subcategories: [
                    BudgetSubCategory(name: "Streaming Services", allocationPercentage: 0.0, description: "Monthly fee for streaming. Example: Netflix subscription."),
                    BudgetSubCategory(name: "Music Services", allocationPercentage: 0.0, description: "Monthly fee for music streaming. Example: Spotify subscription."),
                    BudgetSubCategory(name: "Magazines", allocationPercentage: 0.0, description: "Subscription cost for magazines. Example: Monthly magazine subscription."),
                    BudgetSubCategory(name: "Apps", allocationPercentage: 0.0, description: "Cost for app subscriptions. Example: Premium app services.")
                ],
                description: "Subscription related expenses",
                type: .want
            ),
            // Savings Categories
            BudgetCategory(
                name: "Emergency Fund",
                emoji: "💰",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for unexpected expenses. Example: Medical emergencies or car repairs.",
                type: .saving
            ),
            BudgetCategory(
                name: "Vacation",
                emoji: "✈️",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for trips and holidays. Example: Annual family vacation.",
                type: .saving
            ),
            BudgetCategory(
                name: "New Car",
                emoji: "🚗",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for purchasing a new vehicle. Example: Down payment for a new car.",
                type: .saving
            ),
            BudgetCategory(
                name: "Home Renovation",
                emoji: "🔨",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for home improvement projects. Example: Kitchen remodel or new roof.",
                type: .saving
            ),
            BudgetCategory(
                name: "Investment",
                emoji: "📈",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for investment opportunities. Example: Stocks, bonds, or real estate.",
                type: .saving
            ),
            BudgetCategory(
                name: "Wedding",
                emoji: "💍",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for wedding expenses. Example: Venue, catering, and attire.",
                type: .saving
            ),
            BudgetCategory(
                name: "Education Fund",
                emoji: "🎓",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for educational expenses. Example: College tuition and fees.",
                type: .saving
            ),
            BudgetCategory(
                name: "Retirement",
                emoji: "🏖️",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for retirement. Example: 401(k) or IRA contributions.",
                type: .saving
            ),
            BudgetCategory(
                name: "House Down Payment",
                emoji: "🏠",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for a down payment on a house. Example: 20% down payment for a new home.",
                type: .saving
            ),
            BudgetCategory(
                name: "College Fund",
                emoji: "🎓",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for future college expenses. Example: 529 plan contributions.",
                type: .saving
            ),
            BudgetCategory(
                name: "Emergency Savings",
                emoji: "🚨",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for unexpected emergencies. Example: Medical emergencies or urgent repairs.",
                type: .saving
            ),
            BudgetCategory(
                name: "Travel Fund",
                emoji: "🌍",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for travel and adventures. Example: International trips or weekend getaways.",
                type: .saving
            ),
            BudgetCategory(
                name: "Gadgets",
                emoji: "📱",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for gadgets and electronics. Example: New smartphone or laptop.",
                type: .saving
            ),
            BudgetCategory(
                name: "Fitness",
                emoji: "💪",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for fitness and health expenses. Example: Gym membership or fitness equipment.",
                type: .saving
            ),
            BudgetCategory(
                name: "Charity",
                emoji: "🎁",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for charitable donations. Example: Donations to non-profits or causes.",
                type: .saving
            ),
            BudgetCategory(
                name: "Business Investment",
                emoji: "🏢",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for business investments. Example: Funding a startup or expanding a business.",
                type: .saving
            ),
            BudgetCategory(
                name: "Clothing Fund",
                emoji: "👗",
                allocationPercentage: 0.0,
                subcategories: [],
                description: "Savings for clothing and accessories. Example: Seasonal wardrobe updates.",
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
