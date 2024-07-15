import SwiftUI

struct CategorySelectionView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @Binding var selectedCategories: [BudgetCategory]
    var paymentFrequency: PaymentCadence
    var paycheckAmountText: String

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose the categories for your budget")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.top, 16)
                    .padding(.leading, 16)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(budgetCategoryStore.categories) { category in
                            CategoryRow(category: category, isSelected: selectedCategories.contains(where: { $0.id == category.id })) {
                                if let index = selectedCategories.firstIndex(where: { $0.id == category.id }) {
                                    selectedCategories.remove(at: index)
                                } else {
                                    selectedCategories.append(category)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer()

            NavigationLink(destination: SubcategorySelectionView(selectedCategories: $selectedCategories, paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText).environmentObject(BudgetCategoryStore.shared)) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .shadow(radius: 5)
            }
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct CategoryRow: View {
    var category: BudgetCategory
    var isSelected: Bool
    var toggleSelection: () -> Void

    var body: some View {
        Button(action: {
            toggleSelection()
        }) {
            HStack {
                Text(category.emoji)
                    .font(.largeTitle)
                    .padding(.trailing, 8)
                Text(category.name)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .padding(.trailing, 8)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CategorySelectionView(selectedCategories: .constant([]), paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
