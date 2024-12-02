import SwiftUI

struct ItemDropdown: View {
    @Binding var selectedItem: AffordabilityItem?
    private let items = AffordabilityItem.allCases
    @State private var isExpanded = false
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    if let item = selectedItem {
                        HStack(spacing: 8) {
                            Text(item.emoji)
                            Text(item.name)
                                .foregroundColor(.black)
                        }
                    } else {
                        Text("Select what you want to afford...")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }

            if isExpanded {
                ZStack {
                    Color.white
                    VStack(spacing: 0) {
                        ForEach(items, id: \.self) { item in
                            Button(action: {
                                selectedItem = item
                                isExpanded = false
                            }) {
                                HStack(spacing: 12) {
                                    Text(item.emoji)
                                    Text(item.name)
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .cornerRadius(8)
                .shadow(radius: 2)
            }
        }
    }
}

struct ContextualInput: View {
    let item: AffordabilityItem
    @Binding var amount: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(getInputLabel())
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("$")
                TextField("0", text: $amount)
                    .keyboardType(.decimalPad)
                if showsMonthlyIndicator() {
                    Text("/month")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private func getInputLabel() -> String {
        switch item {
        case .house:
            return "Enter the total price of the home"
        case .car:
            return "Enter the total price of the car"
        case .vacation:
            return "Enter how much you want to save monthly"
        case .wedding:
            return "Enter your total wedding budget"
        case .education:
            return "Enter the total cost of education"
        case .retirement:
            return "Enter desired monthly income in retirement"
        case .emergencyFund:
            return "Enter target emergency fund amount"
        }
    }
    
    private func showsMonthlyIndicator() -> Bool {
        switch item {
        case .vacation, .retirement:
            return true
        default:
            return false
        }
    }
}

// Define affordability ratios and calculations
struct AffordabilityRatios {
    static let house = (
        maxDebtRatio: 0.28,
        downPaymentPercent: 0.20,
        propertyTaxRate: 0.015,
        insuranceRate: 0.005,
        maintenanceRate: 0.01,
        interestRate: 0.065,
        loanTerm: 30.0
    )
    
    static let car = (
        maxMonthlyPaymentRatio: 0.15,
        downPaymentPercent: 0.20,
        insuranceRate: 0.015,
        maintenanceRate: 0.02,
        interestRate: 0.045,
        loanTerm: 5.0
    )
    
    static let vacation = (
        maxSpendingRatio: 0.05,
        bufferPercent: 0.15
    )
    
    static let wedding = (
        maxSpendingRatio: 0.20,
        bufferPercent: 0.10
    )
    
    static let education = (
        maxDebtRatio: 0.12,
        bufferPercent: 0.20
    )
    
    static let retirement = (
        savingsRate: 0.15,
        returnRate: 0.07,
        inflationRate: 0.03,
        yearsInRetirement: 30.0
    )
    
    static let emergencyFund = (
        monthsCovered: 6.0,
        bufferPercent: 0.10
    )
}

struct AffordabilityCalculatorView: View {
    @State private var selectedItem: AffordabilityItem?
    @State private var amount: String = ""
    @State private var calculationResult: AffordabilityResult?
    @State private var showAddToBudgetSheet = false
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.05)
    
    struct AffordabilityResult {
        let requiredIncome: Double
        let monthlyPayment: Double
        let downPayment: Double
        let isAffordable: Bool
        let details: [(label: String, value: Double)]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Calculator Card
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Affordability Calculator")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(customGreen)
                    
                    // Content
                    VStack(spacing: 20) {
                        ItemDropdown(selectedItem: $selectedItem)
                        
                        if let item = selectedItem {
                            ContextualInput(item: item, amount: $amount)
                        }
                        
                        // Amount Input
                        if let selectedItem = selectedItem {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(selectedItem.inputPrompt)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("$")
                                    TextField("Amount", text: $amount)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: amount) { _ in
                                            calculateAffordability()
                                        }
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Analysis Results Section
                        if let result = calculationResult {
                            VStack(spacing: 16) {
                                // Income Requirement Card
                                VStack(spacing: 8) {
                                    Text("Required Annual Income")
                                        .font(.headline)
                                    Text(formatCurrency(result.requiredIncome))
                                        .font(.system(size: 32, weight: .bold))
                                        
                                    HStack(spacing: 4) {
                                        Image(systemName: result.isAffordable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        Text(result.isAffordable ? "You can afford this" : "Out of reach")
                                    }
                                    .foregroundColor(result.isAffordable ? customGreen : .red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(result.isAffordable ? customGreen.opacity(0.1) : .red.opacity(0.1))
                                    .cornerRadius(16)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                
                                // Payment Details
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Payment Breakdown")
                                        .font(.headline)
                                    
                                    ForEach(result.details, id: \.label) { detail in
                                        HStack {
                                            Text(detail.label)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(formatCurrency(detail.value))
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    
                                    Button(action: { showAddToBudgetSheet = true }) {
                                        HStack {
                                            Image(systemName: "plus")
                                            Text("Add to Budget")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .foregroundColor(.white)
                                        .background(customGreen)
                                        .cornerRadius(10)
                                    }
                                    .padding(.top, 8)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 5)
            }
            .padding()
        }
        .sheet(isPresented: $showAddToBudgetSheet) {
            if let item = selectedItem, let result = calculationResult {
                AddToBudgetView(item: item, amount: result.monthlyPayment)
                    .environmentObject(budgetCategoryStore)
            }
        }
    }
    
    private func calculateAffordability() {
        guard let selectedItem = selectedItem,
              let value = Double(amount.filter { "0123456789.".contains($0) }) else {
            calculationResult = nil
            return
        }
        
        let assumptions = AffordabilityRatios.self
        
        switch selectedItem {
        case .house:
            let ratio = assumptions.house
            let downPayment = value * ratio.downPaymentPercent
            let loanAmount = value - downPayment
            let monthlyRate = ratio.interestRate / 12
            let totalPayments = ratio.loanTerm * 12
            
            let monthlyPI = loanAmount *
                (monthlyRate * pow(1 + monthlyRate, totalPayments)) /
                (pow(1 + monthlyRate, totalPayments) - 1)
            
            let monthlyTaxes = (value * ratio.propertyTaxRate) / 12
            let monthlyInsurance = (value * ratio.insuranceRate) / 12
            let monthlyMaintenance = (value * ratio.maintenanceRate) / 12
            
            let totalMonthlyPayment = monthlyPI + monthlyTaxes + monthlyInsurance + monthlyMaintenance
            let requiredIncome = totalMonthlyPayment / ratio.maxDebtRatio * 12
            
            calculationResult = AffordabilityResult(
                requiredIncome: requiredIncome,
                monthlyPayment: totalMonthlyPayment,
                downPayment: downPayment,
                isAffordable: requiredIncome <= budgetCategoryStore.currentMonthlyIncome * 12,
                details: [
                    ("Required Annual Income", requiredIncome),
                    ("Monthly Payment", totalMonthlyPayment),
                    ("Down Payment", downPayment)
                ]
            )
            
        // Add other cases for car, vacation, etc.
        default:
            break
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// Add To Budget View
struct AddToBudgetView: View {
    let item: AffordabilityItem
    let amount: Double
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Add implementation
                Text("Add to Budget Sheet")
            }
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
