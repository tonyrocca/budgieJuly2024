import SwiftUI

struct EditCategoryView: View {
    var category: BudgetCategory
    var subcategory: BudgetSubCategory? = nil
    @Binding var budgieModel: BudgieModel
    @State private var newAmountText: String = ""
    @State private var originalAmount: Double
    @Environment(\.presentationMode) var presentationMode
    var onDismiss: () -> Void

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    init(category: BudgetCategory, subcategory: BudgetSubCategory? = nil, budgieModel: Binding<BudgieModel>, onDismiss: @escaping () -> Void) {
        self.category = category
        self.subcategory = subcategory
        self._budgieModel = budgieModel
        self.onDismiss = onDismiss
        
        let amount = subcategory?.amount ?? category.amount ?? 0
        self._originalAmount = State(initialValue: amount)
        self._newAmountText = State(initialValue: currencyFormatter.string(from: NSNumber(value: amount)) ?? "")
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Edit \(subcategory?.name ?? category.name)")
                    .font(.headline)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Category: \(category.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let subcategory = subcategory {
                    Text("Subcategory: \(subcategory.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text("Original Amount: \(currencyFormatter.string(from: NSNumber(value: originalAmount)) ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("New Amount:")
                Spacer()
                TextField("Enter amount", text: $newAmountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Button(action: save) {
                Text("Save")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .frame(width: 300, height: 300)
    }
    
    private func save() {
        if let newAmount = Double(newAmountText.replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) {
            if let subcategory = subcategory {
                budgieModel.updateSubcategory(category: category, subcategory: subcategory, newAmount: newAmount)
            } else {
                budgieModel.updateCategory(category, newAmount: newAmount)
            }
            presentationMode.wrappedValue.dismiss()
            onDismiss()
        }
    }
}
