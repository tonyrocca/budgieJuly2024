import SwiftUI

struct ImproveBudgetPopup: View {
    @Binding var isShowing: Bool
    @Binding var selectedCategories: [BudgetCategory]
    @Binding var budgieModel: BudgieModel
    @State private var recommendations: [BudgetCategory] = []
    @State private var selectedCategoryIds: Set<UUID> = Set()

    var isSurplus: Bool
    var budgetCategoryStore: BudgetCategoryStore

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        VStack {
            Text(isSurplus ? "Recommended Categories to Add" : "Recommended Categories to Reduce")
                .font(.headline)
                .padding()

            ScrollView {
                ForEach(recommendations) { category in
                    HStack {
                        Text("\(category.emoji) \(category.name)")
                        Spacer()
                        Text("\(currencyFormatter.string(from: NSNumber(value: recommendedAmount(for: category))) ?? "$0")")
                        Image(systemName: selectedCategoryIds.contains(category.id) ? "checkmark.circle.fill" : "circle")
                            .onTapGesture {
                                if selectedCategoryIds.contains(category.id) {
                                    selectedCategoryIds.remove(category.id)
                                } else {
                                    selectedCategoryIds.insert(category.id)
                                }
                            }
                    }
                    .padding()
                }
            }

            HStack {
                Button("Cancel") {
                    withAnimation {
                        isShowing = false
                    }
                }
                .padding()

                Spacer()

                Button(isSurplus ? "Add" : "Remove") {
                    confirmChanges()
                }
                .padding()
                .disabled(selectedCategoryIds.isEmpty)
            }
        }
        .onAppear {
            recommendations = budgieModel.generateRecommendations(forSurplus: isSurplus, selectedCategories: selectedCategories)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 20)
        .padding()
        .background(
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }
        )
    }

    private func recommendedAmount(for category: BudgetCategory) -> Double {
        // Logic to calculate recommended amount
        return 0.0 // Placeholder
    }

    private func confirmChanges() {
        if isSurplus {
            // Add selected categories
            for id in selectedCategoryIds {
                if let category = budgetCategoryStore.categories.first(where: { $0.id == id }) {
                    budgieModel.addCategory(category)
                }
            }
        } else {
            // Remove selected categories
            for id in selectedCategoryIds {
                if let category = selectedCategories.first(where: { $0.id == id }) {
                    budgieModel.removeCategory(category)
                }
            }
        }

        // Recalculate allocations and update selected categories
        budgieModel.calculateAllocations(selectedCategories: selectedCategories)
        selectedCategories = budgetCategoryStore.categories

        withAnimation {
            isShowing = false
        }
    }
}
