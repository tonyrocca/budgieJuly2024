import SwiftUI

enum AffordabilityItem: CaseIterable, Identifiable {
    case house, car, vacation, wedding, education, retirement, emergencyFund
    
    var id: Self { self }
    
    var name: String {
        switch self {
        case .house: return "home"
        case .car: return "car"
        case .vacation: return "vacation"
        case .wedding: return "wedding"
        case .education: return "education"
        case .retirement: return "retirement"
        case .emergencyFund: return "emergency fund"
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
        case .house: return "Home Affordability"
        case .car: return "Car Affordability"
        case .vacation: return "Vacation Savings"
        case .wedding: return "Wedding Budget"
        case .education: return "Education Fund"
        case .retirement: return "Retirement Savings"
        case .emergencyFund: return "Emergency Fund"
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
    
    var assumptionKeys: [String] {
        switch self {
        case .house: return ["Annual Income Multiplier", "Down Payment Percentage", "Interest Rate", "Loan Term (Years)"]
        case .car: return ["Income Percentage", "Loan Term (Years)", "Interest Rate"]
        case .vacation: return ["Income Percentage", "Duration (Days)", "Daily Budget"]
        case .wedding: return ["Income Percentage", "Guest Count", "Cost per Guest"]
        case .education: return ["Annual Tuition", "Number of Years", "Annual Increase Rate"]
        case .retirement: return ["Income Replacement Ratio", "Years in Retirement", "Annual Return Rate"]
        case .emergencyFund: return ["Months of Expenses", "Monthly Expenses"]
        }
    }
    
    var defaultAssumptions: [String: Any] {
        switch self {
        case .house: return ["Annual Income Multiplier": 3.0, "Down Payment Percentage": 0.2, "Interest Rate": 0.035, "Loan Term (Years)": 30.0]
        case .car: return ["Income Percentage": 0.35, "Loan Term (Years)": 4.0, "Interest Rate": 0.045]
        case .vacation: return ["Income Percentage": 0.05, "Duration (Days)": 7.0, "Daily Budget": 200.0]
        case .wedding: return ["Income Percentage": 0.5, "Guest Count": 100.0, "Cost per Guest": 250.0]
        case .education: return ["Annual Tuition": 30000.0, "Number of Years": 4.0, "Annual Increase Rate": 0.05]
        case .retirement: return ["Income Replacement Ratio": 0.8, "Years in Retirement": 30.0, "Annual Return Rate": 0.07]
        case .emergencyFund: return ["Months of Expenses": 6.0, "Monthly Expenses": 3000.0]
        }
    }
    
    func calculateAmount(annualIncome: Double, assumptions: [String: Any]) -> Double {
        let defaultAssumptions = self.defaultAssumptions
        switch self {
        case .house:
            let multiplier = assumptions["Annual Income Multiplier"] as? Double ?? defaultAssumptions["Annual Income Multiplier"] as! Double
            return annualIncome * multiplier
        case .car:
            let percentage = assumptions["Income Percentage"] as? Double ?? defaultAssumptions["Income Percentage"] as! Double
            return annualIncome * percentage
        case .vacation:
            let percentage = assumptions["Income Percentage"] as? Double ?? defaultAssumptions["Income Percentage"] as! Double
            return annualIncome * percentage
        case .wedding:
            let percentage = assumptions["Income Percentage"] as? Double ?? defaultAssumptions["Income Percentage"] as! Double
            return annualIncome * percentage
        case .education:
            let annualTuition = assumptions["Annual Tuition"] as? Double ?? defaultAssumptions["Annual Tuition"] as! Double
            let years = assumptions["Number of Years"] as? Double ?? defaultAssumptions["Number of Years"] as! Double
            return annualTuition * years
        case .retirement:
            let ratio = assumptions["Income Replacement Ratio"] as? Double ?? defaultAssumptions["Income Replacement Ratio"] as! Double
            let years = assumptions["Years in Retirement"] as? Double ?? defaultAssumptions["Years in Retirement"] as! Double
            return annualIncome * ratio * years
        case .emergencyFund:
            let months = assumptions["Months of Expenses"] as? Double ?? defaultAssumptions["Months of Expenses"] as! Double
            let monthlyExpenses = assumptions["Monthly Expenses"] as? Double ?? defaultAssumptions["Monthly Expenses"] as! Double
            return months * monthlyExpenses
        }
    }
}

struct AffordabilityView: View {
    @ObservedObject var budgieModel: BudgieModel
    @State private var expandedItem: AffordabilityItem?
    @State private var editingItem: AffordabilityItem?
    @State private var assumptions: [AffordabilityItem: [String: Any]] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text("Affordability Breakdown")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Based on your income, here's what you could potentially afford:")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)

                // Affordability Cards
                VStack(spacing: 8) {
                    ForEach(AffordabilityItem.allCases, id: \.self) { item in
                        affordabilityCard(item: item)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(UIColor.systemGray6))
    }

    private func affordabilityCard(item: AffordabilityItem) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(item.emoji)
                    .font(.system(size: 20))
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: expandedItem == item ? "chevron.up" : "chevron.down")
                    .foregroundColor(.black)
                    .font(.system(size: 12))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGray4)) // Slightly darker gray for the header
            .onTapGesture {
                withAnimation {
                    expandedItem = expandedItem == item ? nil : item
                }
            }
            
            // Main Content
            HStack {
                Text(currencyFormatter.string(from: NSNumber(value: item.calculateAmount(annualIncome: calculateAnnualIncome(), assumptions: assumptions[item] ?? [:]))) ?? "$0")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.white)
            
            // Expandable Content
            if expandedItem == item {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("How it's calculated:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    
                    ForEach(item.assumptionKeys, id: \.self) { key in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(item.color)
                                .font(.system(size: 12))
                            Text("\(key): \(formatAssumption(key: key, value: assumptions[item]?[key] ?? item.defaultAssumptions[key]!))")
                                .font(.subheadline)
                        }
                    }
                    
                    Button(action: {
                        editingItem = item
                    }) {
                        Text("Edit Assumptions")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.white)
                .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(item: $editingItem) { item in
            EditAssumptionsView(item: item, assumptions: assumptions[item] ?? [:]) { updatedAssumptions in
                assumptions[item] = updatedAssumptions
            }
        }
    }
    
    private func calculateAnnualIncome() -> Double {
        budgieModel.paymentCadence.monthlyEquivalent(from: budgieModel.paycheckAmount) * 12
    }

    private func formatAssumption(key: String, value: Any) -> String {
        if let doubleValue = value as? Double {
            if key.lowercased().contains("rate") || key.lowercased().contains("percentage") {
                return String(format: "%.2f%%", doubleValue * 100)
            } else {
                return currencyFormatter.string(from: NSNumber(value: doubleValue)) ?? "$0"
            }
        }
        return String(describing: value)
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
}

struct EditAssumptionsView: View {
    let item: AffordabilityItem
    @State private var assumptions: [String: Any]
    let onSave: ([String: Any]) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    init(item: AffordabilityItem, assumptions: [String: Any], onSave: @escaping ([String: Any]) -> Void) {
        self.item = item
        self._assumptions = State(initialValue: assumptions.isEmpty ? item.defaultAssumptions : assumptions)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(item.assumptionKeys, id: \.self) { key in
                    if let value = assumptions[key] as? Double {
                        HStack {
                            Text(key)
                            Spacer()
                            TextField("Value", text: Binding(
                                get: { String(format: "%.2f", value) },
                                set: {
                                    if let newValue = Double($0) {
                                        assumptions[key] = newValue
                                    }
                                }
                            ))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        }
                    }
                }
            }
            .navigationBarTitle("Edit Assumptions", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    onSave(assumptions)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
