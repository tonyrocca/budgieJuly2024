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
    
    // MARK: - Published Properties
    @Published var categories: [BudgetCategory]
    @Published private(set) var allocations: [UUID: Double] = [:]
    @Published private(set) var budgetSummary: BudgetSummary = .empty
    
    // MARK: - Private State
    private var monthlyIncome: Double = 0
    private var paymentCadence: PaymentCadence = .monthly
    
    // MARK: - Models
    struct BudgetSummary {
        var totalAllocated: Double = 0
        var totalDebts: Double = 0
        var totalNeeds: Double = 0
        var totalWants: Double = 0
        var totalSavings: Double = 0
        var surplusOrDeficit: Double = 0
        var recommendations: [String] = []
        
        static var empty: BudgetSummary { BudgetSummary() }
    }
    
    // MARK: - Budget Rules
    private struct CategoryLimits {
        // Major financial category limits (as percentage of monthly income)
        static let debt = (min: 0.0, max: 0.36)  // Max 36% debt-to-income ratio
        static let savings = (min: 0.10, max: 0.30)  // 10-30% for savings
        static let discretionary = (min: 0.0, max: 0.30)  // Max 30% for wants
        
        // Core expense category limits (as percentage of monthly income)
        static let housing = (min: 0.25, max: 0.28)  // Reduced from 0.35
        static let transportation = (min: 0.10, max: 0.12)  // Reduced from 0.15
        static let food = (min: 0.10, max: 0.12)  // Reduced from 0.15
        static let utilities = (min: 0.05, max: 0.08)  // Reduced from 0.10
        static let healthcare = (min: 0.05, max: 0.08)  // Reduced from 0.10
        static let personalCare = (min: 0.02, max: 0.03)  // Reduced from 0.05
        static let education = (min: 0.05, max: 0.10)  // Reduced from 0.15
        static let pets = (min: 0.01, max: 0.03)  // Reduced from 0.05
        static let entertainment = (min: 0.02, max: 0.05)  // Reduced from 0.08
        static let subscriptions = (min: 0.01, max: 0.02)  // Reduced from 0.03
        
        // Subcategory percentage breakdowns
        static let housingSubcategories: [String: Double] = [
            "Mortgage": 0.70,
            "Rent": 0.70,
            "Utilities": 0.15,
            "Home Maintenance": 0.10,
            "Property Tax": 0.03,
            "Home Insurance": 0.02
        ]
        
        static let transportationSubcategories: [String: Double] = [
            "Car Payment": 0.50,
            "Public Transportation": 0.10,
            "Ride Share": 0.05,
            "Tolls": 0.05,
            "Maintenance": 0.15,
            "Fuel": 0.10,
            "Car Insurance": 0.05
        ]
        
        static let foodSubcategories: [String: Double] = [
            "Groceries": 0.70,
            "Dining Out": 0.15,
            "Snacks": 0.05,
            "Meal Delivery": 0.10
        ]
        
        static let healthcareSubcategories: [String: Double] = [
            "Insurance Premiums": 0.50,
            "Doctor Visits": 0.20,
            "Medications": 0.15,
            "Dental Care": 0.10,
            "Vision Care": 0.05
        ]
        
        static let utilitiesSubcategories: [String: Double] = [
            "Electricity": 0.35,
            "Water": 0.15,
            "Gas": 0.15,
            "Internet": 0.20,
            "Cable": 0.10,
            "Trash": 0.05
        ]
        
        static let petsSubcategories: [String: Double] = [
            "Food": 0.40,
            "Vet Visits": 0.30,
            "Medications": 0.15,
            "Grooming": 0.05,
            "Toys": 0.05,
            "Pet Insurance": 0.05
        ]
        
        static let subscriptionsSubcategories: [String: Double] = [
            "Streaming Services": 0.40,
            "Music Services": 0.20,
            "Magazines": 0.10,
            "Apps": 0.15,
            "News Subscriptions": 0.15
        ]
        
        static let entertainmentSubcategories: [String: Double] = [
            "Movies": 0.20,
            "Games": 0.20,
            "Concerts": 0.25,
            "Sports Events": 0.20,
            "Hobbies": 0.15
        ]
        
        static let personalCareSubcategories: [String: Double] = [
            "Haircuts": 0.30,
            "Skincare": 0.20,
            "Cosmetics": 0.20,
            "Spa Treatments": 0.15,
            "Gym Membership": 0.15
        ]
        
        static let educationSubcategories: [String: Double] = [
            "Tuition": 0.70,
            "Books & Supplies": 0.15,
            "Online Courses": 0.10,
            "School Fees": 0.05
        ]
    }
    
    private func allocateExpenseSubcategories(for category: BudgetCategory, monthlyIncome: Double) -> [UUID: Double] {
        var subcategoryAllocations: [UUID: Double] = [:]
        let selectedSubcategories = category.subcategories.filter { $0.isSelected }
        
        if selectedSubcategories.isEmpty { return [:] }
        
        // Get category limits and subcategory percentages based on category name
        let categoryLimit: (min: Double, max: Double)
        let subcategoryPercentages: [String: Double]
        
        switch category.name {
        case "Housing":
            categoryLimit = CategoryLimits.housing
            subcategoryPercentages = CategoryLimits.housingSubcategories
        case "Transportation":
            categoryLimit = CategoryLimits.transportation
            subcategoryPercentages = CategoryLimits.transportationSubcategories
        case "Food":
            categoryLimit = CategoryLimits.food
            subcategoryPercentages = CategoryLimits.foodSubcategories
        case "Healthcare":
            categoryLimit = CategoryLimits.healthcare
            subcategoryPercentages = CategoryLimits.healthcareSubcategories
        case "Utilities":
            categoryLimit = CategoryLimits.utilities
            subcategoryPercentages = CategoryLimits.utilitiesSubcategories
        case "Pets":
            categoryLimit = CategoryLimits.pets
            subcategoryPercentages = CategoryLimits.petsSubcategories
        case "Subscriptions":
            categoryLimit = CategoryLimits.subscriptions
            subcategoryPercentages = CategoryLimits.subscriptionsSubcategories
        case "Entertainment":
            categoryLimit = CategoryLimits.entertainment
            subcategoryPercentages = CategoryLimits.entertainmentSubcategories
        case "Personal Care":
            categoryLimit = CategoryLimits.personalCare
            subcategoryPercentages = CategoryLimits.personalCareSubcategories
        case "Education":
            categoryLimit = CategoryLimits.education
            subcategoryPercentages = CategoryLimits.educationSubcategories
        default:
            categoryLimit = (min: 0.02, max: 0.05) // Default to 2-5% for other categories
            subcategoryPercentages = [:]
        }
        
        // Calculate maximum monthly allocation for this category
            let maxMonthlyAllocation = monthlyIncome * categoryLimit.max
            
            // Convert to per-paycheck amount first
            let maxPerPaycheckAllocation = convertToPaycheckAmount(maxMonthlyAllocation)
            
            // Distribute among subcategories
            for subcategory in selectedSubcategories {
                let percentage = subcategoryPercentages[subcategory.name] ??
                    (1.0 / Double(selectedSubcategories.count))
                
                // Calculate subcategory allocation from the per-paycheck amount
                let subcategoryAllocation = maxPerPaycheckAllocation * percentage
                
                subcategoryAllocations[subcategory.id] = subcategoryAllocation
            }
            
            return subcategoryAllocations
        }
    
    // Add this method inside BudgetCategoryStore.swift
    private func convertToPaycheckAmount(_ monthlyAmount: Double) -> Double {
        switch paymentCadence {
        case .weekly:
            return monthlyAmount / 4.33  // More accurate weekly division (52/12)
        case .biWeekly:
            return monthlyAmount / 2.167  // More accurate bi-weekly division (26/12)
        case .semiMonthly:
            return monthlyAmount / 2.0
        case .monthly:
            return monthlyAmount
        }
    }

    // Add this method to validate total allocations don't exceed income
    private func validateAndAdjustAllocations(_ allocations: [UUID: Double], maxIncome: Double) -> [UUID: Double] {
        var adjustedAllocations = allocations
        let totalAllocated = allocations.values.reduce(0, +)
        
        if totalAllocated > maxIncome {
            let adjustmentRatio = maxIncome / totalAllocated
            for (key, value) in allocations {
                adjustedAllocations[key] = value * adjustmentRatio
            }
        }
        
        return adjustedAllocations
    }
    
    private struct PriorityWeights {
        static let weights: [Int: Double] = [
            1: 1.0,   // Essential, must fund
            2: 0.8,   // High priority
            3: 0.6,   // Medium priority
            4: 0.4,   // Low priority
            5: 0.2    // Optional
        ]
    }

    
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
                    BudgetSubCategory(name: "Mortgage", allocationPercentage: 25.0, description: "Monthly payments for a home loan. Example: Fixed-rate mortgage.", priority: 1),
                    BudgetSubCategory(name: "Rent", allocationPercentage: 30.0, description: "Monthly rental payments for housing. Example: Apartment or house rent.", priority: 1),
                    BudgetSubCategory(name: "Utilities", allocationPercentage: 5.0, description: "Payments for essential home services. Example: Electricity and water bills.", priority: 1),
                    BudgetSubCategory(name: "Home Maintenance", allocationPercentage: 3.0, description: "Expenses for maintaining the home. Example: Repairing appliances.", priority: 1),
                    BudgetSubCategory(name: "Property Tax", allocationPercentage: 1.5, description: "Annual tax on property value, typically paid monthly or annually.", priority: 1),
                    BudgetSubCategory(name: "Home Insurance", allocationPercentage: 1.5, description: "Insurance covering home-related risks. Example: Fire or flood insurance.", priority: 1)
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
                    BudgetSubCategory(name: "Car Payment", allocationPercentage: 10.0, description: "Monthly payment for vehicle financing. Example: Car loan.", priority: 2),
                    BudgetSubCategory(name: "Public Transportation", allocationPercentage: 2.5, description: "Costs for public transit services. Example: Bus or train fare.", priority: 2),
                    BudgetSubCategory(name: "Ride Share", allocationPercentage: 1.5, description: "Expenses for ride-hailing services. Example: Uber or Lyft.", priority: 2),
                    BudgetSubCategory(name: "Tolls", allocationPercentage: 0.5, description: "Fees for using toll roads. Example: Highway tolls.", priority: 2),
                    BudgetSubCategory(name: "Maintenance", allocationPercentage: 2.0, description: "Costs for vehicle upkeep. Example: Oil changes and tire rotations.", priority: 2),
                    BudgetSubCategory(name: "Fuel", allocationPercentage: 5.0, description: "Expenses for vehicle fuel. Example: Gasoline or diesel.", priority: 2),
                    BudgetSubCategory(name: "Car Insurance", allocationPercentage: 2.5, description: "Monthly or yearly premium for car insurance. Example: Comprehensive insurance.", priority: 2)
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
                    BudgetSubCategory(name: "Groceries", allocationPercentage: 10.0, description: "Weekly or monthly food purchases. Example: Supermarket shopping.", priority: 1),
                    BudgetSubCategory(name: "Dining Out", allocationPercentage: 3.0, description: "Meals at restaurants or cafes. Example: Dinner at a local restaurant.", priority: 4),
                    BudgetSubCategory(name: "Snacks", allocationPercentage: 1.0, description: "Costs for snacks and treats. Example: Chips, candy, or cookies.", priority: 4),
                    BudgetSubCategory(name: "Meal Delivery", allocationPercentage: 2.0, description: "Food delivered to home. Example: UberEats or DoorDash.", priority: 4)
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
                    BudgetSubCategory(name: "Insurance Premiums", allocationPercentage: 5.0, description: "Monthly payments for health insurance. Example: Medical insurance premiums.", priority: 1),
                    BudgetSubCategory(name: "Doctor Visits", allocationPercentage: 1.5, description: "Costs for regular and emergency doctor consultations. Example: Annual check-ups.", priority: 1),
                    BudgetSubCategory(name: "Medications", allocationPercentage: 1.0, description: "Expenses for prescription and over-the-counter medications. Example: Antibiotics or pain relief.", priority: 1),
                    BudgetSubCategory(name: "Dental Care", allocationPercentage: 1.0, description: "Costs for dental services. Example: Cleanings and fillings.", priority: 1),
                    BudgetSubCategory(name: "Vision Care", allocationPercentage: 0.5, description: "Expenses related to eye care. Example: Eye exams or glasses.", priority: 1)
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
                    BudgetSubCategory(name: "Electricity", allocationPercentage: 3.0, description: "Monthly payment for electric services. Example: Utility company bills.", priority: 2),
                    BudgetSubCategory(name: "Water", allocationPercentage: 1.5, description: "Monthly costs for water supply. Example: Water utility fees.", priority: 2),
                    BudgetSubCategory(name: "Gas", allocationPercentage: 1.5, description: "Expenses for gas services. Example: Heating gas for home.", priority: 2),
                    BudgetSubCategory(name: "Internet", allocationPercentage: 2.0, description: "Monthly fee for internet access. Example: Broadband service.", priority: 2),
                    BudgetSubCategory(name: "Cable", allocationPercentage: 1.0, description: "Subscription costs for cable TV. Example: Basic or premium channels.", priority: 2),
                    BudgetSubCategory(name: "Trash", allocationPercentage: 0.5, description: "Fees for waste collection services. Example: Weekly trash pickup.", priority: 2)
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
                    BudgetSubCategory(name: "Food", allocationPercentage: 1.5, description: "Monthly pet food expenses. Example: Dog or cat food.", priority: 3),
                    BudgetSubCategory(name: "Vet Visits", allocationPercentage: 2.0, description: "Routine and emergency veterinary visits. Example: Annual check-ups or surgeries.", priority: 3),
                    BudgetSubCategory(name: "Medications", allocationPercentage: 0.5, description: "Expenses for pet medications. Example: Flea and tick prevention.", priority: 1),
                    BudgetSubCategory(name: "Grooming", allocationPercentage: 0.5, description: "Costs for pet grooming services. Example: Bathing or haircuts.", priority: 3),
                    BudgetSubCategory(name: "Toys", allocationPercentage: 0.5, description: "Spending on pet toys. Example: Chew toys or interactive toys.", priority: 3),
                    BudgetSubCategory(name: "Pet Insurance", allocationPercentage: 1.0, description: "Monthly premium for pet health insurance. Example: Coverage for illness or accidents.", priority: 3)
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
                    BudgetSubCategory(name: "Streaming Services", allocationPercentage: 1.5, description: "Costs for video streaming platforms. Example: Netflix or Hulu subscriptions.", priority: 5),
                    BudgetSubCategory(name: "Music Services", allocationPercentage: 0.5, description: "Monthly fee for music streaming. Example: Spotify or Apple Music.", priority: 5),
                    BudgetSubCategory(name: "Magazines", allocationPercentage: 0.5, description: "Subscriptions for print or digital magazines. Example: Monthly or annual magazine fees.", priority: 5),
                    BudgetSubCategory(name: "Apps", allocationPercentage: 0.5, description: "Paid apps or app subscriptions. Example: Productivity or utility apps.", priority: 5),
                    BudgetSubCategory(name: "News Subscriptions", allocationPercentage: 0.5, description: "Online or print news service fees. Example: The New York Times digital subscription.", priority: 5)
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
                    BudgetSubCategory(name: "Movies", allocationPercentage: 1.0, description: "Expenses for movie outings. Example: Tickets to a movie theater.", priority: 5),
                    BudgetSubCategory(name: "Games", allocationPercentage: 1.5, description: "Purchases of video or board games. Example: New releases or DLCs.", priority: 5),
                    BudgetSubCategory(name: "Concerts", allocationPercentage: 1.5, description: "Tickets for live music events. Example: Concerts or music festivals.", priority: 5),
                    BudgetSubCategory(name: "Sports Events", allocationPercentage: 1.5, description: "Costs for attending sports games. Example: Stadium tickets.", priority: 5),
                    BudgetSubCategory(name: "Hobbies", allocationPercentage: 1.0, description: "Expenses for hobby-related activities. Example: Supplies for crafting or photography.", priority: 5)
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
                    BudgetSubCategory(name: "Haircuts", allocationPercentage: 1.0, description: "Monthly or bi-monthly haircut expenses. Example: Visits to a hair salon.", priority: 4),
                    BudgetSubCategory(name: "Skincare", allocationPercentage: 0.5, description: "Costs for skincare products or treatments. Example: Moisturizers or facials.", priority: 4),
                    BudgetSubCategory(name: "Cosmetics", allocationPercentage: 0.5, description: "Spending on beauty products. Example: Makeup or skincare items.", priority: 4),
                    BudgetSubCategory(name: "Spa Treatments", allocationPercentage: 0.5, description: "Expenses for spa visits. Example: Massages or other relaxation services.", priority: 4),
                    BudgetSubCategory(name: "Gym Membership", allocationPercentage: 1.0, description: "Monthly membership fees for fitness centers. Example: Gym or yoga classes.", priority: 4)
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
                    BudgetSubCategory(name: "Tuition", allocationPercentage: 5.0, description: "Annual or semester-based tuition fees. Example: University tuition.", priority: 3),
                    BudgetSubCategory(name: "Books & Supplies", allocationPercentage: 1.0, description: "Expenses for educational materials. Example: Textbooks or lab supplies.", priority: 3),
                    BudgetSubCategory(name: "Online Courses", allocationPercentage: 0.5, description: "Costs for online learning. Example: Course fees on platforms like Coursera.", priority: 3),
                    BudgetSubCategory(name: "School Fees", allocationPercentage: 0.5, description: "Miscellaneous school-related fees. Example: Activity fees or lab charges.", priority: 3)
                ],
                description: "Education related expenses",
                type: .need,
                priority: 3
            )
            ,
            
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
    
    func updateIncome(_ amount: Double, cadence: PaymentCadence) {
            monthlyIncome = adjustAmountForPaymentCadence(amount, cadence: cadence)
            paymentCadence = cadence
            recalculateAllocations()
        }
        
        func updateCategory(_ category: BudgetCategory, amount: Double) {
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index].amount = amount
                recalculateAllocations()
            }
        }
    
    // MARK: - Core Allocation Logic
    
    // MARK: - Private Implementation
    private func recalculateAllocations() {
        allocations.removeAll()
        var remainingIncome = monthlyIncome
        var summary = BudgetSummary()
        
        // 1. Allocate Fixed Debts First
        let (debtAllocations, debtTotal) = allocateDebts()
        allocations.merge(debtAllocations) { _, new in new }
        remainingIncome -= debtTotal
        summary.totalDebts = debtTotal
        
        // 2. Allocate Essential Needs
        let (needsAllocations, needsTotal) = allocateNeeds(remainingAfterDebt: remainingIncome)
        allocations.merge(needsAllocations) { _, new in new }
        remainingIncome -= needsTotal
        summary.totalNeeds = needsTotal
        
        // 3. Allocate Emergency Savings
        let (savingsAllocations, savingsTotal) = allocateSavings(remainingAfterNeeds: remainingIncome)
        allocations.merge(savingsAllocations) { _, new in new }
        remainingIncome -= savingsTotal
        summary.totalSavings = savingsTotal
        
        // 4. Allocate Discretionary Spending
        let (wantsAllocations, wantsTotal) = allocateWants(remainingAfterSavings: remainingIncome)
        allocations.merge(wantsAllocations) { _, new in new }
        remainingIncome -= wantsTotal
        summary.totalWants = wantsTotal
        
        // NEW: Recalculate expense category totals after all allocations are done
        updateExpenseCategoryTotals()
        
        // 5. Handle Surplus or Deficit
        summary.surplusOrDeficit = remainingIncome
        if remainingIncome < 0 {
            rebalanceForDeficit(deficit: abs(remainingIncome))
            // After rebalancing, update expense totals again
            updateExpenseCategoryTotals()
        } else {
            handleSurplus(surplus: remainingIncome)
        }
        
        // 6. Update Summary and Notify
        summary.totalAllocated = monthlyIncome - remainingIncome
        summary.recommendations = generateRecommendations()
        budgetSummary = summary
        
        objectWillChange.send()
    }
    
    // Add new helper method for expense category totals
    // Add a method to update expense category totals
    func updateExpenseCategoryTotals() {
        // Get all expense categories (needs and wants)
        let expenseCategories = categories.filter {
            ($0.type == .need || $0.type == .want) &&
            $0.isSelected
        }
        
        for categoryIndex in categories.indices {
            let category = categories[categoryIndex]
            if (category.type == .need || category.type == .want) && category.isSelected {
                // Calculate total from selected subcategories only
                let selectedSubcategories = category.subcategories.filter { $0.isSelected }
                let categoryTotal = selectedSubcategories.reduce(0.0) { $0 + ($1.amount ?? 0) }
                
                // Update both the category amount and the allocation
                categories[categoryIndex].amount = categoryTotal
                allocations[category.id] = categoryTotal
            }
        }
    }
    
    // MARK: - Category-Specific Allocation Methods
    
    private func allocateDebts() -> (allocations: [UUID: Double], total: Double) {
        var debtAllocations: [UUID: Double] = [:]
        var totalDebtPayments = 0.0
        
        let debtCategories = categories
            .filter { $0.type == .debt && $0.isSelected }
            .sorted { $0.priority < $1.priority }
        
        let maxDebtPayment = monthlyIncome * CategoryLimits.debt.max
        
        for debt in debtCategories {
            if let amount = debt.amount, let dueDate = debt.dueDate {
                let monthlyPayment = calculateMonthlyDebtPayment(totalAmount: amount, dueDate: dueDate)
                
                if totalDebtPayments + monthlyPayment <= maxDebtPayment {
                    debtAllocations[debt.id] = monthlyPayment
                    totalDebtPayments += monthlyPayment
                } else {
                    let remaining = maxDebtPayment - totalDebtPayments
                    debtAllocations[debt.id] = remaining
                    totalDebtPayments += remaining
                    break
                }
            }
        }
        
        return (debtAllocations, totalDebtPayments)
    }
    
    private func allocateNeeds(remainingAfterDebt: Double) -> (allocations: [UUID: Double], total: Double) {
        var needsAllocations: [UUID: Double] = [:]
        var totalNeeds = 0.0
        
        let needCategories = categories
            .filter { $0.type == .need && $0.isSelected }
            .sorted { $0.priority < $1.priority }
        
        for category in needCategories {
            if category.subcategories.isEmpty {
                let allocation = calculateNeedAllocation(
                    category: category,
                    remainingBudget: remainingAfterDebt,
                    alreadyAllocated: totalNeeds
                )
                needsAllocations[category.id] = allocation
                totalNeeds += allocation
            } else {
                // For categories with subcategories, sum up subcategory amounts
                let subcategoryTotal = category.subcategories
                    .filter { $0.isSelected }
                    .reduce(0.0) { total, subcategory in
                        let subcategoryAmount = subcategory.amount ?? 0
                        needsAllocations[subcategory.id] = subcategoryAmount
                        return total + subcategoryAmount
                    }
                needsAllocations[category.id] = subcategoryTotal
                totalNeeds += subcategoryTotal
            }
        }
        
        return (needsAllocations, totalNeeds)
    }
    
    private func allocateSavings(remainingAfterNeeds: Double) -> (allocations: [UUID: Double], total: Double) {
        var savingsAllocations: [UUID: Double] = [:]
        var totalSavings = 0.0
        
        let savingsCategories = categories
            .filter { $0.type == .saving && $0.isSelected }
            .sorted { $0.priority < $1.priority }
        
        // Ensure emergency fund gets priority
        if let emergencyFund = savingsCategories.first(where: { $0.name == "Emergency Fund" }) {
            let emergencyAllocation = min(
                remainingAfterNeeds * CategoryLimits.savings.min,
                emergencyFund.amount ?? (monthlyIncome * 0.1)
            )
            savingsAllocations[emergencyFund.id] = emergencyAllocation
            totalSavings += emergencyAllocation
        }
        
        let remainingForSavings = min(
            remainingAfterNeeds * CategoryLimits.savings.max - totalSavings,
            remainingAfterNeeds - totalSavings
        )
        
        if remainingForSavings > 0 {
            let otherSavings = savingsCategories.filter { $0.name != "Emergency Fund" }
            let allocations = distributeBudget(
                amount: remainingForSavings,
                among: otherSavings
            )
            savingsAllocations.merge(allocations) { _, new in new }
            totalSavings += allocations.values.reduce(0, +)
        }
        
        return (savingsAllocations, totalSavings)
    }
    
    private func allocateWants(remainingAfterSavings: Double) -> (allocations: [UUID: Double], total: Double) {
        var wantsAllocations: [UUID: Double] = [:]
        var totalWants = 0.0
        
        let wantCategories = categories
            .filter { $0.type == .want && $0.isSelected }
            .sorted { $0.priority < $1.priority }
        
        for category in wantCategories {
            if category.subcategories.isEmpty {
                let categoryTotal = min(
                    remainingAfterSavings * CategoryLimits.discretionary.max,
                    category.amount ?? (remainingAfterSavings * 0.05)
                )
                wantsAllocations[category.id] = categoryTotal
                totalWants += categoryTotal
            } else {
                // For categories with subcategories, sum up subcategory amounts
                let selectedSubcategories = category.subcategories.filter { $0.isSelected }
                let subcategoryTotal = selectedSubcategories.reduce(0.0) { total, subcategory in
                    let amount = subcategory.amount ?? 0
                    wantsAllocations[subcategory.id] = amount
                    return total + amount
                }
                wantsAllocations[category.id] = subcategoryTotal
                totalWants += subcategoryTotal
            }
        }
        
        return (wantsAllocations, totalWants)
    }
    
    // MARK: - Helper Methods
    
    private func calculateNeedAllocation(category: BudgetCategory, remainingBudget: Double, alreadyAllocated: Double) -> Double {
        let limit = categoryLimit(for: category.name)
        let maxAllocation = remainingBudget * limit.max
        let minAllocation = remainingBudget * limit.min
        
        // Start with requested amount or calculated minimum
        var allocation = category.amount ?? minAllocation
        
        // Apply priority-based adjustment
        let priorityWeight = PriorityWeights.weights[category.priority] ?? 0.2
        allocation *= priorityWeight
        
        // Ensure we're within limits
        allocation = min(maxAllocation, max(minAllocation, allocation))
        
        return allocation
    }
    
    private func categoryLimit(for categoryName: String) -> (min: Double, max: Double) {
        switch categoryName {
        case "Housing": return CategoryLimits.housing
        case "Food": return CategoryLimits.food
        case "Transportation": return CategoryLimits.transportation
        case "Utilities": return CategoryLimits.utilities
        case "Healthcare": return CategoryLimits.healthcare
        default: return (min: 0.02, max: 0.10) // Default limits
        }
    }
    
    func addCategory(name: String, emoji: String, allocationPercentage: Double, subcategories: [BudgetSubCategory], description: String, type: CategoryType, amount: Double? = nil, dueDate: Date? = nil, isSelected: Bool = false, priority: Int? = nil) {
            let category = BudgetCategory(
                name: name,
                emoji: emoji,
                allocationPercentage: allocationPercentage,
                subcategories: subcategories,
                description: description,
                type: type,
                amount: amount,
                dueDate: dueDate,
                isSelected: isSelected,
                priority: priority ?? 0
            )
            categories.append(category)
            recalculateAllocations()
        }
        
        func deleteCategory(at index: Int) {
            categories.remove(at: index)
            recalculateAllocations()
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
    
    func updateExpenseCategoryAmounts() {
        for index in categories.indices {
            var category = categories[index]
            if category.type == .need || category.type == .want { // Only update expense categories
                let totalSubcategoryAmount = category.subcategories.reduce(0.0) { $0 + ($1.amount ?? 0) }
                category.amount = totalSubcategoryAmount
                categories[index] = category // Ensure the change is applied to the array
            }
        }
    }

    func updateSubcategoryAmount(_ category: BudgetCategory, subcategory: BudgetSubCategory, newAmount: Double) {
        if let categoryIndex = categories.firstIndex(where: { $0.id == category.id }),
           let subcategoryIndex = categories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
            // Update the subcategory amount
            categories[categoryIndex].subcategories[subcategoryIndex].amount = newAmount
            
            // Recalculate the category total
            let newTotal = categories[categoryIndex].subcategories
                .filter { $0.isSelected }
                .reduce(0.0) { $0 + ($1.amount ?? 0) }
            categories[categoryIndex].amount = newTotal
            
            // Update allocations
            recalculateAllocations()
        }
    }
    
    func updateCategoryAmount(_ category: BudgetCategory, amount: Double) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].amount = amount
            updateExpenseCategoryAmounts() // Ensure the consistency of expense amounts after an update
        }
    }
}

extension BudgetCategoryStore {
    // MARK: - Payment & Amount Calculations
    
    private func adjustAmountForPaymentCadence(_ amount: Double, cadence: PaymentCadence) -> Double {
        switch cadence {
        case .weekly: return amount * 52 / 12
        case .biWeekly: return amount * 26 / 12
        case .semiMonthly: return amount * 24 / 12
        case .monthly: return amount
        }
    }
    
    private func calculateMonthlyDebtPayment(totalAmount: Double, dueDate: Date) -> Double {
        let calendar = Calendar.current
        let monthsUntilDue = calendar.dateComponents([.month], from: Date(), to: dueDate).month ?? 1
        return totalAmount / Double(max(1, monthsUntilDue))
    }
    
    // MARK: - Category Allocation Methods
    
    
    // MARK: - Distribution Helpers
    
    private func distributeBudget(amount: Double, among categories: [BudgetCategory]) -> [UUID: Double] {
        var allocations: [UUID: Double] = [:]
        let totalWeight = categories.reduce(0.0) { $0 + (PriorityWeights.weights[Int($1.priority)] ?? 0.2) }
        
        for category in categories {
            let weight = PriorityWeights.weights[category.priority] ?? 0.2
            var allocation = (amount * weight) / totalWeight
            
            // If category has a specific amount requested, try to honor it within reason
            if let requestedAmount = category.amount {
                allocation = min(allocation * 1.2, requestedAmount) // Allow up to 20% more than calculated
            }
            
            allocations[category.id] = allocation
        }
        
        return allocations
    }
    
    private func distributeAmongSubcategories(category: BudgetCategory, totalAmount: Double) -> [UUID: Double] {
        var subcategoryAllocations: [UUID: Double] = [:]
        let selectedSubcategories = category.subcategories.filter { $0.isSelected }
        
        if selectedSubcategories.isEmpty { return [:] }
        
        let totalPercentage = selectedSubcategories.reduce(0.0) { $0 + $1.allocationPercentage }
        
        for subcategory in selectedSubcategories {
            let proportion = subcategory.allocationPercentage / totalPercentage
            subcategoryAllocations[subcategory.id] = totalAmount * proportion
        }
        
        return subcategoryAllocations
    }
    
    // MARK: - Budget Balancing
    
    private func rebalanceForDeficit(deficit: Double) {
        var remainingDeficit = deficit
        var currentAllocations = allocations
        
        // First reduce discretionary spending
        let wantCategories = categories.filter { $0.type == .want && $0.isSelected }
        for category in wantCategories {
            if let currentAmount = currentAllocations[category.id] {
                let reduction = min(currentAmount * 0.5, remainingDeficit) // Cut by up to 50%
                currentAllocations[category.id] = currentAmount - reduction
                remainingDeficit -= reduction
            }
        }
        
        // Then adjust non-essential needs if needed
        if remainingDeficit > 0 {
            let nonEssentialNeeds = categories.filter {
                $0.type == .need &&
                $0.isSelected &&
                $0.priority > 2
            }
            
            for category in nonEssentialNeeds {
                if let currentAmount = currentAllocations[category.id] {
                    let reduction = min(currentAmount * 0.3, remainingDeficit) // Cut by up to 30%
                    currentAllocations[category.id] = currentAmount - reduction
                    remainingDeficit -= reduction
                }
            }
        }
        
        allocations = currentAllocations
    }
    
    private func handleSurplus(surplus: Double) {
        // Allocate surplus to savings and debt paydown
        let additionalSavings = surplus * 0.7 // 70% to savings
        let additionalDebtPayment = surplus * 0.3 // 30% to debt
        
        // Distribute additional savings
        if let emergencyFund = categories.first(where: {
            $0.type == .saving &&
            $0.name == "Emergency Fund" &&
            $0.isSelected
        }) {
            allocations[emergencyFund.id, default: 0] += additionalSavings
        }
        
        // Apply extra to highest priority debt
        if let highestPriorityDebt = categories.filter({
            $0.type == .debt &&
            $0.isSelected
        }).min(by: { $0.priority < $1.priority }) {
            allocations[highestPriorityDebt.id, default: 0] += additionalDebtPayment
        }
    }
    
    // MARK: - Recommendations
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Check debt-to-income ratio
        let totalDebt = categories
            .filter { $0.type == .debt && $0.isSelected }
            .compactMap { allocations[$0.id] }
            .reduce(0, +)
        
        let debtRatio = totalDebt / monthlyIncome
        if debtRatio > CategoryLimits.debt.max {
            recommendations.append("Your debt payments are high. Consider debt consolidation or speaking with a financial advisor.")
        }
        
        // Check emergency fund
        if let emergencyFund = categories.first(where: { $0.name == "Emergency Fund" && $0.isSelected }),
           let allocation = allocations[emergencyFund.id],
           allocation < monthlyIncome * 3 {
            recommendations.append("Build your emergency fund to cover 3-6 months of expenses.")
        }
        
        // Check housing costs
        if let housing = categories.first(where: { $0.name == "Housing" && $0.isSelected }),
           let allocation = allocations[housing.id],
           allocation > monthlyIncome * CategoryLimits.housing.max {
            recommendations.append("Your housing costs exceed recommended limits. Consider ways to reduce these expenses.")
        }
        
        return recommendations
    }
}

extension BudgetCategoryStore {
    var currentMonthlyIncome: Double {
        monthlyIncome
    }
}
