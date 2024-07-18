import SwiftUI

struct CategorySelectionView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @Binding var selectedCategories: [BudgetCategory]
    var paymentFrequency: PaymentCadence
    var paycheckAmountText: String

    var body: some View {
        VStack(spacing: 16) {
            Text("What budget categories do you need for your budget?")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 16)
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(budgetCategoryStore.categories.filter { $0.type == .need || $0.type == .want }) { category in
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
                                if selectedCategories.contains(where: { $0.id == category.id }) {
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
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            NavigationLink(destination: SubcategorySelectionView(selectedCategories: $selectedCategories, paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText).environmentObject(budgetCategoryStore)) {
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

    private func toggleCategorySelection(_ category: BudgetCategory) {
        if let index = selectedCategories.firstIndex(where: { $0.id == category.id }) {
            selectedCategories.remove(at: index)
        } else {
            selectedCategories.append(category)
        }
    }
}

struct CategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CategorySelectionView(selectedCategories: .constant([]), paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
