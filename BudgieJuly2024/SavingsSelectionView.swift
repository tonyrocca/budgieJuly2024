import SwiftUI

struct SavingsSelectionView: View {
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    var body: some View {
        VStack {
            Text("Select your savings goals.")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            List {
                ForEach(budgetCategoryStore.categories.filter { $0.type == .saving }) { category in
                    Toggle(isOn: Binding(
                        get: { category.isSelected },
                        set: { newValue in
                            if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                budgetCategoryStore.categories[index].isSelected = newValue
                            }
                        }
                    )) {
                        HStack {
                            Text(category.emoji)
                            Text(category.name)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            Spacer()

            NavigationLink(destination: ContentView(selectedCategories: budgetCategoryStore.categories.filter { $0.isSelected }, paymentFrequency: paymentFrequency, paycheckAmountText: income)
                .environmentObject(budgetCategoryStore)) {
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
        .navigationTitle("Select Savings Goals")
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct SavingsSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SavingsSelectionView(income: .constant("5000"), paymentFrequency: .constant(.monthly))
            .environmentObject(BudgetCategoryStore.shared)
    }
}
