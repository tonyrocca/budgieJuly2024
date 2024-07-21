import SwiftUI

struct SubcategorySelectionView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @Binding var selectedCategories: [BudgetCategory]
    var paymentFrequency: PaymentCadence
    var paycheckAmountText: String

    @State private var expandedCategory: UUID?

    private func toggleSubcategorySelection(_ subcategory: BudgetSubCategory, in category: BudgetCategory) {
        if let categoryIndex = selectedCategories.firstIndex(where: { $0.id == category.id }),
           let subcategoryIndex = selectedCategories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
            selectedCategories[categoryIndex].subcategories[subcategoryIndex].isSelected.toggle()
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Pick your subcategories")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 16)
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(selectedCategories) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(category.emoji)
                                    .font(.largeTitle)
                                Text(category.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        if expandedCategory == category.id {
                                            expandedCategory = nil
                                        } else {
                                            expandedCategory = category.id
                                        }
                                    }
                                }) {
                                    Image(systemName: expandedCategory == category.id ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)

                            if expandedCategory == category.id {
                                ForEach(category.subcategories.indices, id: \.self) { subcategoryIndex in
                                    let subcategory = category.subcategories[subcategoryIndex]
                                    Button(action: {
                                        toggleSubcategorySelection(subcategory, in: category)
                                    }) {
                                        HStack {
                                            Text(subcategory.name)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if subcategory.isSelected {
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
                        }
                        .padding(.top)
                        Divider()
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            NavigationLink(destination: ContentView(selectedCategories: selectedCategories, paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText).environmentObject(BudgetCategoryStore.shared)) {
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

struct SubcategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SubcategorySelectionView(selectedCategories: .constant([]), paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
