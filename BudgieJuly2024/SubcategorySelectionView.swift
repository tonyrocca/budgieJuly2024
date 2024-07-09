import SwiftUI

struct SubcategorySelectionView: View {
    @Binding var selectedCategories: [BudgetCategory]
    @State private var showNextButton = false

    var paymentFrequency: PaymentCadence
    var paycheckAmountText: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Subcategories")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)

            List {
                ForEach(selectedCategories) { category in
                    Section(header: Text(category.name)) {
                        ForEach(category.subcategories) { subcategory in
                            HStack {
                                Text(subcategory.name)
                                Spacer()
                                if subcategory.isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let categoryIndex = selectedCategories.firstIndex(where: { $0.id == category.id }) {
                                    if let subcategoryIndex = selectedCategories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                                        selectedCategories[categoryIndex].subcategories[subcategoryIndex].isSelected.toggle()
                                    }
                                }
                                updateShowNextButton()
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            Spacer()

            if showNextButton {
                NavigationLink(destination: ContentView(selectedCategories: selectedCategories, paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText).environmentObject(BudgetCategoryStore.shared)) {
                    Text("Finish")
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
        showNextButton = selectedCategories.contains { category in
            category.subcategories.contains { $0.isSelected }
        }
    }
}

struct SubcategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SubcategorySelectionView(selectedCategories: .constant([]), paymentFrequency: .monthly, paycheckAmountText: "")
    }
}
