import SwiftUI

struct DebtSelectionView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @Binding var selectedDebtCategories: [BudgetCategory]

    var body: some View {
        VStack(spacing: 16) {
            headerView
            debtCategoryScrollView
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    private var headerView: some View {
        Text("What debt do you have?")
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal, 16)
    }

    private var debtCategoryScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(budgetCategoryStore.categories.filter { $0.type == .debt }) { category in
                    debtCategoryButton(for: category)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func debtCategoryButton(for category: BudgetCategory) -> some View {
        Button(action: {
            toggleCategorySelection(category)
        }) {
            HStack {
                Text(category.emoji)
                    .font(.largeTitle)
                Text(category.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if selectedDebtCategories.contains(where: { $0.id == category.id }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .padding(.trailing, 8)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func toggleCategorySelection(_ category: BudgetCategory) {
        if let index = selectedDebtCategories.firstIndex(where: { $0.id == category.id }) {
            selectedDebtCategories.remove(at: index)
        } else {
            selectedDebtCategories.append(category)
        }
    }
}

struct DebtSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DebtSelectionView(selectedDebtCategories: .constant([]))
            .environmentObject(BudgetCategoryStore.shared)
    }
}
