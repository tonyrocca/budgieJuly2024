import SwiftUI

struct PerfectBudgetView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var perfectBudgieModel: BudgieModel
    @State private var expandedCategoryIndex: UUID? = nil
    @State private var expandedSubCategoryIndex: UUID? = nil
    @State private var showDetails = true
    
    // Calculator states
    @State private var selectedCalculatorItem: AffordabilityItem?
    @State private var desiredAmount: String = ""
    @State private var requiredIncome: Double?
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.05)
    let paycheckAmount: Double
    let paymentCadence: PaymentCadence

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    init(paycheckAmount: Double = 0, paymentCadence: PaymentCadence) {
        self.paycheckAmount = paycheckAmount
        self.paymentCadence = paymentCadence
        self._perfectBudgieModel = State(initialValue: BudgieModel(paycheckAmount: paycheckAmount))
    }

    private var currentAnnualIncome: Double {
        paymentCadence.monthlyEquivalent(from: paycheckAmount) * 12
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Affordability Calculator
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Affordability Calculator")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(customGreen)
                    
                    // Calculator Content
                    VStack(spacing: 16) {
                        // Item Selection
                        VStack(alignment: .leading, spacing: 4) {
                            Menu {
                                ForEach(AffordabilityItem.allCases, id: \.self) { item in
                                    Button(action: {
                                        selectedCalculatorItem = item
                                        calculateRequiredIncome()
                                    }) {
                                        HStack(spacing: 8) {
                                            Text(item.emoji)
                                                .font(.body)
                                            Text(item.title)
                                                .font(.body)
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    if let item = selectedCalculatorItem {
                                        Text(item.emoji)
                                            .font(.body)
                                        Text(item.title)
                                            .font(.body)
                                    } else {
                                        Text("Select what you want to afford...")
                                            .font(.body)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(selectedCalculatorItem == nil ? .secondary : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Amount Input
                        if let item = selectedCalculatorItem {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enter amount")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
                                    Text("$")
                                        .foregroundColor(.primary)
                                        .font(.body)
                                    TextField("0", text: $desiredAmount)
                                        .keyboardType(.numberPad)
                                        .font(.body)
                                        .onChange(of: desiredAmount) { _ in
                                            calculateRequiredIncome()
                                        }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Results
                            if let income = requiredIncome {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Required Annual Income")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(formatCurrency(income))
                                        .font(.system(size: 38, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    if income > currentAnnualIncome {
                                        Text("You need \(formatCurrency(income - currentAnnualIncome)) more in annual income")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("You can afford this with your current income")
                                            .font(.subheadline)
                                            .foregroundColor(customGreen)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 3)
                .padding(.horizontal, 16)
                
            }
        }
    }

    // Add calculator functionality
    private func calculateRequiredIncome() {
        guard let item = selectedCalculatorItem,
              let amount = Double(desiredAmount.filter { "0123456789.".contains($0) }) else {
            requiredIncome = nil
            return
        }
        
        let defaultAssumptions = item.defaultAssumptions
        var testIncome = amount * 2
        let tolerance = 0.01
        var calculatedAmount = 0.0
        
        var low = amount * 0.1
        var high = amount * 10
        
        for _ in 0..<20 {
            testIncome = (low + high) / 2
            calculatedAmount = item.calculateAmount(annualIncome: testIncome, assumptions: defaultAssumptions)
            
            let difference = (calculatedAmount - amount) / amount
            if abs(difference) < tolerance {
                break
            }
            
            if calculatedAmount < amount {
                low = testIncome
            } else {
                high = testIncome
            }
        }
        
        requiredIncome = testIncome
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
