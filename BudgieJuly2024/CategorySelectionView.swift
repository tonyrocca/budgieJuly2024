import SwiftUI

struct CategorySelectionView: View {
    @Binding var selectedCategories: [BudgetCategory]
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var showNextButton = false

    var paymentFrequency: PaymentCadence
    var paycheckAmountText: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Categories")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
            
            List {
                ForEach(budgetCategoryStore.categories) { category in
                    HStack {
                        Text(category.name)
                        Spacer()
                        if selectedCategories.contains(where: { $0.id == category.id }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let index = selectedCategories.firstIndex(where: { $0.id == category.id }) {
                            selectedCategories.remove(at: index)
                        } else {
                            selectedCategories.append(category)
                        }
                        updateShowNextButton()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            Spacer()

            if showNextButton {
                NavigationLink(destination: SubcategorySelectionView(selectedCategories: $selectedCategories, paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText)) {
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
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    private func updateShowNextButton() {
        showNextButton = !selectedCategories.isEmpty
    }
}

struct CategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CategorySelectionView(selectedCategories: .constant([]), paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
