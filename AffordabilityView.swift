import SwiftUI


enum AffordabilityItem: CaseIterable, Identifiable {
    case house, car, vacation, wedding, education, retirement, emergencyFund

    var id: Self { self }

    var name: String {
        switch self {
        case .house: return "House Affordability"
        case .car: return "Car Affordability"
        case .vacation: return "Vacation Savings Per Year"
        case .wedding: return "Wedding You Can Afford"
        case .education: return "Education Fund"
        case .retirement: return "Retirement Savings"
        case .emergencyFund: return "Emergency Savings"
        }
    }

    var emoji: String {
        switch self {
        case .house: return "🏠"
        case .car: return "🚗"
        case .vacation: return "✈️"
        case .wedding: return "💍"
        case .education: return "🎓"
        case .retirement: return "🏖️"
        case .emergencyFund: return "🆘"
        }
    }

    var title: String {
        switch self {
        case .house: return "House Affordability"
        case .car: return "Car Affordability"
        case .vacation: return "Vacation Savings Per Year"
        case .wedding: return "Wedding You Can Afford"
        case .education: return "Education Fund"
        case .retirement: return "Retirement Savings"
        case .emergencyFund: return "Emergency Savings"
        }
    }

    var color: Color {
        switch self {
        case .house: return .blue
        case .car: return .green
        case .vacation: return .orange
        case .wedding: return .pink
        case .education: return .purple
        case .retirement: return .red
        case .emergencyFund: return .yellow
        }
    }

    var description: String {
        switch self {
        case .house: return "Estimated home value you might afford based on your income and current market conditions."
        case .car: return "Suggested car value that aligns with your financial situation and typical auto loan terms."
        case .vacation: return "Recommended vacation budget based on your annual income and average travel costs."
        case .wedding: return "Suggested wedding budget that fits your financial profile and typical wedding expenses."
        case .education: return "Estimated education fund based on average 4-year college costs and potential future increases."
        case .retirement: return "Rough estimate for retirement savings goal based on your current income and retirement age."
        case .emergencyFund: return "Recommended emergency fund to cover unexpected expenses or temporary loss of income."
        }
    }

    var inputPrompt: String {
        switch self {
        case .house:
            return "Enter the price of the home you want to afford."
        case .car:
            return "Enter the price of the car you want to afford."
        case .vacation:
            return "Enter the cost of the vacation you want to take."
        case .wedding:
            return "Enter your wedding budget."
        case .education:
            return "Enter the total cost of your education."
        case .retirement:
            return "Enter your desired annual income during retirement."
        case .emergencyFund:
            return "Enter your monthly expenses."
        }
    }

    func resultMessage(requiredIncome: Double, enteredAmount: Double) -> String {
        switch self {
        case .house:
            return "You need to earn at least \(formatCurrency(requiredIncome)) annually to afford a home priced at \(formatCurrency(enteredAmount))."
        case .car:
            return "An annual income of \(formatCurrency(requiredIncome)) is required to afford a car costing \(formatCurrency(enteredAmount))."
        case .vacation:
            return "To afford a vacation costing \(formatCurrency(enteredAmount)), you should earn at least \(formatCurrency(requiredIncome)) annually."
        case .wedding:
            return "You need an annual income of \(formatCurrency(requiredIncome)) to afford a wedding costing \(formatCurrency(enteredAmount))."
        case .education:
            return "An annual income of \(formatCurrency(requiredIncome)) is needed to afford education costs of \(formatCurrency(enteredAmount))."
        case .retirement:
            return "To have an annual retirement income of \(formatCurrency(enteredAmount)), you need to earn \(formatCurrency(requiredIncome)) now."
        case .emergencyFund:
            return "To build an emergency fund covering \(formatCurrency(enteredAmount)) per month, you need to earn at least \(formatCurrency(requiredIncome)) annually."
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    var assumptionKeys: [String] {
        switch self {
        case .house:
            return [
                "Annual Household Income",
                "Down Payment Saved",
                "Monthly Debt Payments",
                "Credit Score Range",
                "Interest Rate",
                "Loan Term (Years)"
            ]
        case .car:
            return [
                "Down Payment Amount",
                "Trade-in Value",
                "Loan Term (Years)",
                "Interest Rate",
                "Monthly Budget for Payment"
            ]
        case .vacation:
            return [
                "Number of Travelers",
                "Trip Duration (Days)",
                "Daily Budget per Person",
                "Flight Cost per Person",
                "Buffer for Activities"
            ]
        case .wedding:
            return [
                "Guest Count",
                "Cost per Guest",
                "Venue Budget",
                "Month of Wedding",
                "Additional Services Budget" // Photography, music, etc.
            ]
        case .education:
            return [
                "Years of Education",
                "Annual Tuition",
                "Annual Room & Board",
                "Books and Supplies per Year",
                "Annual Increase Rate"
            ]
        case .retirement:
            return [
                "Current Age",
                "Retirement Age",
                "Desired Annual Income",
                "Expected Return Rate",
                "Inflation Rate"
            ]
        case .emergencyFund:
            return [
                "Monthly Housing Cost",
                "Monthly Utilities",
                "Monthly Food Budget",
                "Monthly Insurance Premiums",
                "Months of Coverage"
            ]
        }
    }
    
    var defaultAssumptions: [String: Any] {
        switch self {
        case .house:
            return [
                "Annual Household Income": 80000.0,
                "Down Payment Saved": 50000.0,
                "Monthly Debt Payments": 500.0,
                "Credit Score Range": "700-749",
                "Interest Rate": 0.065,
                "Loan Term (Years)": 30.0
            ]
        case .car:
            return [
                "Down Payment Amount": 5000.0,
                "Trade-in Value": 0.0,
                "Loan Term (Years)": 5.0,
                "Interest Rate": 0.045,
                "Monthly Budget for Payment": 400.0
            ]
        case .vacation:
            return [
                "Number of Travelers": 2,
                "Trip Duration (Days)": 7,
                "Daily Budget per Person": 200.0,
                "Flight Cost per Person": 500.0,
                "Buffer for Activities": 1000.0
            ]
        case .wedding:
            return [
                "Guest Count": 100,
                "Cost per Guest": 200.0,
                "Venue Budget": 10000.0,
                "Month of Wedding": "June",
                "Additional Services Budget": 15000.0
            ]
        case .education:
            return [
                "Years of Education": 4,
                "Annual Tuition": 30000.0,
                "Annual Room & Board": 15000.0,
                "Books and Supplies per Year": 1200.0,
                "Annual Increase Rate": 0.05
            ]
        case .retirement:
            return [
                "Current Age": 30,
                "Retirement Age": 65,
                "Desired Annual Income": 80000.0,
                "Expected Return Rate": 0.07,
                "Inflation Rate": 0.03
            ]
        case .emergencyFund:
            return [
                "Monthly Housing Cost": 2000.0,
                "Monthly Utilities": 300.0,
                "Monthly Food Budget": 600.0,
                "Monthly Insurance Premiums": 400.0,
                "Months of Coverage": 6
            ]
        }
    }
    
    func calculateAmount(annualIncome: Double, assumptions: [String: Any]) -> Double {
       // Helper function to safely get Double values
       func getDouble(_ key: String) -> Double {
           return (assumptions[key] as? Double) ?? (defaultAssumptions[key] as? Double ?? 0)
       }
       
       // Helper function to safely get String values
       func getString(_ key: String) -> String {
           return (assumptions[key] as? String) ?? (defaultAssumptions[key] as? String ?? "")
       }
       
       // Helper function to safely get Int values
       func getInt(_ key: String) -> Int {
           return (assumptions[key] as? Int) ?? (defaultAssumptions[key] as? Int ?? 0)
       }

       switch self {
       case .house:
           let downPayment = getDouble("Down Payment Saved")
           let monthlyDebt = getDouble("Monthly Debt Payments")
           let rate = getDouble("Interest Rate")
           
           let maxMonthlyPayment = min(
               annualIncome * 0.28 / 12, // Front-end ratio
               (annualIncome * 0.36 / 12) - monthlyDebt // Back-end ratio
           )
           
           let monthlyRate = rate / 12
           let terms = getDouble("Loan Term (Years)") * 12
           let maxLoan = maxMonthlyPayment * ((pow(1 + monthlyRate, terms) - 1) / (monthlyRate * pow(1 + monthlyRate, terms)))
           
           return maxLoan + downPayment
           
       case .car:
           let downPayment = getDouble("Down Payment Amount")
           let tradeIn = getDouble("Trade-in Value")
           let monthlyBudget = getDouble("Monthly Budget for Payment")
           let rate = getDouble("Interest Rate")
           let terms = getDouble("Loan Term (Years)") * 12
           
           let monthlyRate = rate / 12
           let maxLoan = monthlyBudget * ((pow(1 + monthlyRate, terms) - 1) / (monthlyRate * pow(1 + monthlyRate, terms)))
           
           return maxLoan + downPayment + tradeIn
           
       case .vacation:
           let travelers = Double(getInt("Number of Travelers"))
           let duration = Double(getInt("Trip Duration (Days)"))
           let dailyBudget = getDouble("Daily Budget per Person")
           let flightCost = getDouble("Flight Cost per Person")
           let activityBuffer = getDouble("Buffer for Activities")
           
           return (travelers * (flightCost + (dailyBudget * duration))) + activityBuffer
           
       case .wedding:
           let guestCount = Double(getInt("Guest Count"))
           let costPerGuest = getDouble("Cost per Guest")
           let venueBudget = getDouble("Venue Budget")
           let additionalServices = getDouble("Additional Services Budget")
           let month = getString("Month of Wedding")
           
           // Month adjustment factor (peak season costs more)
           let seasonalMultiplier = ["June", "September", "October"].contains(month) ? 1.2 : 1.0
           
           return ((guestCount * costPerGuest) + venueBudget + additionalServices) * seasonalMultiplier
           
       case .education:
           let years = Double(getInt("Years of Education"))
           let tuition = getDouble("Annual Tuition")
           let roomAndBoard = getDouble("Annual Room & Board")
           let supplies = getDouble("Books and Supplies per Year")
           let increaseRate = getDouble("Annual Increase Rate")
           
           var totalCost = 0.0
           for year in 0..<Int(years) {
               let yearlyIncrease = pow(1 + increaseRate, Double(year))
               let yearCost = (tuition + roomAndBoard + supplies) * yearlyIncrease
               totalCost += yearCost
           }
           return totalCost
           
       case .retirement:
           let currentAge = Double(getInt("Current Age"))
           let retirementAge = Double(getInt("Retirement Age"))
           let desiredIncome = getDouble("Desired Annual Income")
           let returnRate = getDouble("Expected Return Rate")
           let inflationRate = getDouble("Inflation Rate")
           
           let yearsToRetirement = retirementAge - currentAge
           let yearsInRetirement = 95 - retirementAge  // Planning to age 95
           let realRate = (1 + returnRate) / (1 + inflationRate) - 1
           
           // Using the present value of an annuity formula
           let futureNeed = desiredIncome * pow(1 + inflationRate, yearsToRetirement)
           let annuityFactor = (1 - pow(1 + realRate, -yearsInRetirement)) / realRate
           let totalNeeded = futureNeed * annuityFactor
           
           // Calculate required monthly savings
           let monthlyRate = returnRate / 12
           let months = yearsToRetirement * 12
           let savingsFactor = (pow(1 + monthlyRate, months) - 1) / monthlyRate
           
           return totalNeeded / savingsFactor
           
       case .emergencyFund:
           let housing = getDouble("Monthly Housing Cost")
           let utilities = getDouble("Monthly Utilities")
           let food = getDouble("Monthly Food Budget")
           let insurance = getDouble("Monthly Insurance Premiums")
           let months = Double(getInt("Months of Coverage"))
           
           let monthlyExpenses = housing + utilities + food + insurance
           return monthlyExpenses * months
       }
    }
}

struct SwipeableAffordabilityCardView: View {
   private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
   private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.05)
   
   let item: AffordabilityItem
   @State private var assumptions: [String: Any]
   @State private var isAssumptionsExpanded: Bool = false
   let amount: Double
   let currentAllocation: Double?
   let onEditAssumptions: ([String: Any]) -> Void

   init(item: AffordabilityItem, assumptions: [String: Any], amount: Double, currentAllocation: Double? = nil, onEditAssumptions: @escaping ([String: Any]) -> Void) {
       self.item = item
       self._assumptions = State(initialValue: assumptions)
       self.amount = amount
       self.currentAllocation = currentAllocation
       self.onEditAssumptions = onEditAssumptions
   }

   var body: some View {
       VStack(spacing: 0) {
           // Header
           HStack {
               Text(item.emoji)
                   .font(.system(size: 34))
               Text(item.name)
                   .font(.title3)
                   .fontWeight(.semibold)
                   .foregroundColor(.black)
               Spacer()
           }
           .padding()
           .background(lightGreen)

           // Main Amount Section
           VStack(alignment: .leading, spacing: 4) {
               Text("Total Affordability")
                   .font(.subheadline)
                   .foregroundColor(.secondary)
               Text(formatCurrency(amount))
                   .font(.system(size: 38, weight: .bold))
                   .foregroundColor(.black)
           }
           .frame(maxWidth: .infinity, alignment: .leading)
           .padding()

           // Monthly Payment Section
           VStack(alignment: .leading, spacing: 4) {
               Text("Monthly Payment")
                   .font(.subheadline)
                   .foregroundColor(.secondary)
               Text(formatCurrency(calculateMonthlyPayment()))
                   .font(.headline)
                   .foregroundColor(.primary)
           }
           .frame(maxWidth: .infinity, alignment: .leading)
           .padding(.horizontal)
           .padding(.bottom, 8)

           // Current Allocation Section
           VStack(alignment: .leading, spacing: 4) {
               Text("Your Current Allocation")
                   .font(.subheadline)
                   .foregroundColor(.secondary)
               if let allocation = currentAllocation {
                   Text(formatCurrency(allocation))
                       .font(.headline)
                       .foregroundColor(.green)
               } else {
                   Text("Not currently in your budget")
                       .font(.subheadline)
                       .foregroundColor(.secondary)
                       .italic()
               }
           }
           .frame(maxWidth: .infinity, alignment: .leading)
           .padding(.horizontal)
           .padding(.bottom, 16)

           // Description Section
           VStack(alignment: .leading, spacing: 8) {
               Text("What does this mean?")
                   .font(.headline)
                   .foregroundColor(.primary)
               Text(item.description)
                   .font(.subheadline)
                   .foregroundColor(.secondary)
           }
           .padding(.horizontal)
           .padding(.vertical, 8)
           .frame(maxWidth: .infinity, alignment: .leading)

           // Assumptions Section (Collapsible)
           VStack(alignment: .leading, spacing: 0) {
               Button(action: {
                   withAnimation { isAssumptionsExpanded.toggle() }
               }) {
                   HStack {
                       Text("Assumptions & Calculations")
                           .font(.subheadline)
                           .foregroundColor(.secondary)
                       Spacer()
                       Image(systemName: isAssumptionsExpanded ? "chevron.down.circle" : "chevron.right.circle")
                           .foregroundColor(.secondary)
                           .font(.system(size: 12))
                   }
                   .padding(.horizontal)
                   .padding(.vertical, 8)
               }
               
               if isAssumptionsExpanded {
                   VStack(alignment: .leading, spacing: 12) {
                       // Disclaimer
                       Text("These calculations are based on industry standards and general financial principles. Your actual situation may vary based on factors like location, credit score, and market conditions.")
                           .font(.caption)
                           .foregroundColor(.secondary)
                           .padding(.top, 8)

                       ForEach(item.assumptionKeys, id: \.self) { key in
                           HStack {
                               Text(key)
                                   .font(.subheadline)
                                   .foregroundColor(.secondary)
                               Spacer()
                               Text(formatAssumption(key: key, value: assumptions[key] ?? item.defaultAssumptions[key]!))
                                   .font(.subheadline)
                                   .foregroundColor(.black)
                           }
                       }
                       
                       Button(action: {
                           // Edit assumptions action
                       }) {
                           HStack {
                               Image(systemName: "slider.horizontal.3")
                               Text("Edit Assumptions")
                           }
                           .font(.subheadline)
                           .foregroundColor(customGreen)
                       }
                       .padding(.top, 4)
                   }
                   .padding(.horizontal)
                   .padding(.bottom, 16)
               }
           }
           .background(Color(UIColor.secondarySystemBackground))

           // Add Goal Button
           Button(action: {
               // Add goal action
           }) {
               Text("Add to Goals")
                   .font(.headline)
                   .foregroundColor(.white)
                   .frame(maxWidth: .infinity)
                   .padding()
                   .background(customGreen)
                   .cornerRadius(12)
           }
           .padding()
       }
       .background(Color.white)
       .cornerRadius(16)
       .shadow(radius: 3)
   }

   private func calculateMonthlyPayment() -> Double {
       switch item {
       case .house:
           let loanAmount = amount * (1 - (assumptions["Down Payment Percentage"] as? Double ?? 0.2))
           let rate = (assumptions["Interest Rate"] as? Double ?? 0.035) / 12
           let terms = (assumptions["Loan Term (Years)"] as? Double ?? 30.0) * 12
           return loanAmount * (rate * pow(1 + rate, terms)) / (pow(1 + rate, terms) - 1)
       case .car:
           let loanAmount = amount
           let rate = (assumptions["Interest Rate"] as? Double ?? 0.045) / 12
           let terms = (assumptions["Loan Term (Years)"] as? Double ?? 4.0) * 12
           return loanAmount * (rate * pow(1 + rate, terms)) / (pow(1 + rate, terms) - 1)
       default:
           return amount / 12
       }
   }

   private func formatCurrency(_ amount: Double) -> String {
       let formatter = NumberFormatter()
       formatter.numberStyle = .currency
       formatter.locale = Locale.current
       return formatter.string(from: NSNumber(value: amount)) ?? "$0"
   }

   private func formatAssumption(key: String, value: Any) -> String {
       if let doubleValue = value as? Double {
           if key.lowercased().contains("rate") || key.lowercased().contains("percentage") {
               return "\(Int(doubleValue * 100))%"
           } else if key.lowercased().contains("year") {
               return "\(Int(doubleValue)) years"
           } else if key.lowercased().contains("multiplier") {
               return "\(doubleValue)x"
           } else {
               return formatCurrency(doubleValue)
           }
       }
       return String(describing: value)
   }
}

struct AffordabilityView: View {
    @ObservedObject var budgieModel: BudgieModel
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var assumptions: [AffordabilityItem: [String: Any]] = {
        // Initialize with default assumptions for each item
        var initialAssumptions: [AffordabilityItem: [String: Any]] = [:]
        AffordabilityItem.allCases.forEach { item in
            initialAssumptions[item] = item.defaultAssumptions
        }
        return initialAssumptions
    }()
    @State private var editingItem: AffordabilityItem?
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                ForEach(AffordabilityItem.allCases, id: \.id) { item in
                    ScrollView {
                        // Safely get assumptions with default fallback
                        let itemAssumptions = assumptions[item] ?? item.defaultAssumptions
                        let calculatedAmount = item.calculateAmount(
                            annualIncome: calculateAnnualIncome(),
                            assumptions: itemAssumptions
                        )
                        
                        SwipeableAffordabilityCardView(
                            item: item,
                            assumptions: itemAssumptions,
                            amount: calculatedAmount,
                            currentAllocation: getCurrentAllocation(for: item)
                        ) { updatedAssumptions in
                            assumptions[item] = updatedAssumptions
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(customGreen)
                UIPageControl.appearance().pageIndicatorTintColor = UIColor(customGreen.opacity(0.2))
                
                // Initialize assumptions on appear if needed
                if assumptions.isEmpty {
                    AffordabilityItem.allCases.forEach { item in
                        assumptions[item] = item.defaultAssumptions
                    }
                }
            }
        }
    }
    
    private func getCurrentAllocation(for item: AffordabilityItem) -> Double? {
        // Helper function to find category by name
        func findCategory(name: String) -> Double? {
            let categories = budgetCategoryStore.categories.filter { $0.isSelected }
            
            // First try to find exact match
            if let category = categories.first(where: { $0.name == name }),
               let allocation = budgieModel.allocations[category.id] {
                return allocation
            }
            
            // Then try to find in subcategories
            for category in categories {
                if let subcategory = category.subcategories.first(where: { $0.name == name }),
                   let allocation = budgieModel.allocations[subcategory.id] {
                    return allocation
                }
            }
            
            return nil
        }
        
        // Match items to budget categories
        switch item {
        case .house:
            return findCategory(name: "Mortgage") ?? findCategory(name: "Rent")
        case .car:
            return findCategory(name: "Car Payment")
        case .vacation:
            return findCategory(name: "Vacation")
        case .wedding:
            return findCategory(name: "Wedding")
        case .education:
            return findCategory(name: "Education Fund")
        case .retirement:
            return findCategory(name: "Retirement")
        case .emergencyFund:
            return findCategory(name: "Emergency Fund")
        }
    }
    
    private func calculateAnnualIncome() -> Double {
        budgieModel.paymentCadence.monthlyEquivalent(from: budgieModel.paycheckAmount) * 12
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
}
    
