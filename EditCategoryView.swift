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
        ZStack {
            BlurView(style: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                HStack {
                    Text("Edit \(subcategory?.name ?? category.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
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
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Amount:")
                        .font(.headline)
                    TextField("Enter amount", text: $newAmountText)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(10)
                }
                
                Button(action: save) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal)
        }
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

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
