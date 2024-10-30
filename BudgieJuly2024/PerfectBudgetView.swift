import SwiftUI

struct PerfectBudgetView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var perfectBudgieModel: BudgieModel
    @State private var expandedCategoryIndex: UUID? = nil
    @State private var expandedSubCategoryIndex: UUID? = nil
    @State private var showDetails = true

    let paycheckAmount: Double
    let paymentCadence: PaymentCadence

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    init(paycheckAmount: Double = 0, paymentCadence: PaymentCadence) {
        self.paycheckAmount = paycheckAmount
        self.paymentCadence = paymentCadence
        self._perfectBudgieModel = State(initialValue: BudgieModel(paycheckAmount: paycheckAmount))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                paycheckTotalView()
                    .padding(.top, 8)
                allocationListView()
            }
        }
        .onAppear {
            calculatePerfectBudget()
        }
    }

    private func paycheckTotalView() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Perfect Budget Total")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: paycheckAmount)) ?? "$0")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private func allocationListView() -> some View {
        VStack(spacing: 1) {
            ForEach(budgetCategoryStore.categories.filter { $0.isSelected }) { category in
                categoryView(category)
            }
        }
        .padding(.horizontal)
    }

    private func categoryView(_ category: BudgetCategory) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(category.emoji) \(category.name)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: perfectBudgieModel.perfectAllocations[category.id] ?? 0)) ?? "$0")")
                    .font(.headline)
                    .foregroundColor(Color.primary)
                Image(systemName: expandedCategoryIndex == category.id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.black)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandedCategoryIndex = expandedCategoryIndex == category.id ? nil : category.id
                }
            }

            if expandedCategoryIndex == category.id {
                if category.type == .saving || category.type == .debt {
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        descriptionView(for: category)
                    }
                } else {
                    expenseCategoryView(for: category)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: expandedCategoryIndex == category.id ? 10 : 5)
                .stroke(Color.gray.opacity(expandedCategoryIndex == category.id ? 0.3 : 0.1), lineWidth: expandedCategoryIndex == category.id ? 1 : 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }

    private func expenseCategoryView(for category: BudgetCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(category.subcategories.filter { $0.isSelected }) { subcategory in
                subcategoryView(for: subcategory, in: category)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .transition(.opacity)
    }

    private func subcategoryView(for subcategory: BudgetSubCategory, in category: BudgetCategory) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(subcategory.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: perfectBudgieModel.perfectAllocations[subcategory.id] ?? 0)) ?? "$0")")
                    .font(.subheadline)
                    .foregroundColor(Color.primary)
                Image(systemName: expandedSubCategoryIndex == subcategory.id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.black)
                    .font(.footnote)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandedSubCategoryIndex = expandedSubCategoryIndex == subcategory.id ? nil : subcategory.id
                }
            }

            if expandedSubCategoryIndex == subcategory.id {
                VStack(spacing: 0) {
                    descriptionView(for: subcategory)
                        .padding(.top, 8)
                }
                .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private func descriptionView(for item: Any) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text(description(for: item))
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
    }

    private func description(for item: Any) -> String {
        if let category = item as? BudgetCategory {
            return category.description
        } else if let subcategory = item as? BudgetSubCategory {
            return subcategory.description
        }
        return ""
    }

    private func calculatePerfectBudget() {
        perfectBudgieModel.paymentCadence = paymentCadence
        perfectBudgieModel.paycheckAmount = paycheckAmount

        let selectedCategories = budgetCategoryStore.categories.filter { $0.isSelected }
        perfectBudgieModel.calculatePerfectBudget(selectedCategories: selectedCategories)
    }
}
