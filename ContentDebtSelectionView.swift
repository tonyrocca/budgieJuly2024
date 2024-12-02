import UIKit // Add this import
import SwiftUI

struct ContentDebtSelectionView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var selectedDebts: Set<UUID> = []
    @State private var showAddDebtForm = false
    @State private var newDebtName = ""
    @State private var debtAmounts: [UUID: String] = [:]
    @State private var selectedDates: [UUID: Date] = [:]
    @State private var showDatePicker: UUID? = nil
    @State private var showDebtDetailsInput = false

    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)

    var availableDebts: [BudgetCategory] {
        budgetCategoryStore.categories.filter { $0.type == .debt && !$0.isSelected }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(showDebtDetailsInput ? "Enter debt details" : "Select your debt categories")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(showDebtDetailsInput ? "Enter your total debt amount owed and when it is due." : "Choose the debt you currently are paying off.")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)

            if showDebtDetailsInput {
                // Debt Details Input
                debtDetailsInputView
            } else {
                // Debt Categories Selection
                debtCategorySelectionView
            }
            
            Spacer()
            
            // Next or Done Button
            Button(action: {
                if showDebtDetailsInput {
                    // Update selected categories in the store
                    let selected = budgetCategoryStore.categories.filter { selectedDebts.contains($0.id) }
                    for category in selected {
                        var newCategory = category
                        newCategory.isSelected = true
                        if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                            budgetCategoryStore.categories[index] = newCategory
                            budgetCategoryStore.categories[index].amount = Double(debtAmounts[category.id] ?? "0")
                            budgetCategoryStore.categories[index].dueDate = selectedDates[category.id] ?? defaultDate()
                        }
                    }
                    // Dismiss the sheet
                    isPresented = false
                } else {
                    // Move to debt details input step
                    showDebtDetailsInput = true
                }
            }) {
                Text(showDebtDetailsInput ? "Done" : "Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(customGreen)
                    .cornerRadius(10)
                    .shadow(color: customGreen.opacity(0.3), radius: 5)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .disabled(!showDebtDetailsInput && selectedDebts.isEmpty || (showDebtDetailsInput && !isFormComplete()))
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .padding(.top, 0)
        
        // Add Debt Modal
        if showAddDebtForm {
            AddDebtCategoryModal(
                isPresented: $showAddDebtForm,
                newDebtName: $newDebtName,
                onAdd: addDebtCategory
            )
        }
    }

    // MARK: - Debt Category Selection View
    private var debtCategorySelectionView: some View {
        VStack(spacing: 0) {
            ForEach(availableDebts) { debt in
                ToggleRow(
                    isOn: Binding(
                        get: { selectedDebts.contains(debt.id) },
                        set: { isSelected in
                            if isSelected {
                                selectedDebts.insert(debt.id)
                            } else {
                                selectedDebts.remove(debt.id)
                            }
                        }
                    ),
                    icon: debt.emoji,
                    text: debt.name
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .font(.body)
                
                if debt.id != availableDebts.last?.id {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }

    // MARK: - Debt Details Input View
    private var debtDetailsInputView: some View {
        VStack(spacing: 16) {
            ForEach(budgetCategoryStore.categories.filter { selectedDebts.contains($0.id) }) { category in
                VStack(spacing: 0) {
                    // Category Header
                    HStack {
                        Text(category.emoji)
                        Text(category.name)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(lightGreen)

                    // Amount and Date inputs
                    VStack(spacing: 12) {
                        // Amount Input
                        HStack {
                            Text("Amount:")
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            HStack {
                                Text("$")
                                    .foregroundColor(.primary)
                                TextField("0", text: binding(for: category.id))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }

                        // Due Date Input
                        HStack {
                            Text("Due date:")
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {
                                showDatePicker = showDatePicker == category.id ? nil : category.id
                            }) {
                                Text(monthYearFormatter.string(from: selectedDates[category.id] ?? defaultDate()))
                                    .foregroundColor(.primary)
                                Image(systemName: "calendar")
                            }
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }

                        if showDatePicker == category.id {
                            MonthYearPickerView(
                                selection: Binding(
                                    get: { self.selectedDates[category.id] ?? self.defaultDate() },
                                    set: {
                                        self.selectedDates[category.id] = $0
                                        self.showDatePicker = nil
                                    }
                                ),
                                range: dateRange
                            )
                            .frame(height: 200)
                            .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Add Debt Category
    private func addDebtCategory() {
        let newCategory = BudgetCategory(
            name: newDebtName,
            emoji: "💳",
            allocationPercentage: 0.0,
            subcategories: [],
            description: "Custom debt category",
            type: .debt,
            isSelected: true,
            priority: 5
        )
        budgetCategoryStore.addCategory(
            name: newDebtName,
            emoji: "💳",
            allocationPercentage: 0.0,
            subcategories: [],
            description: "Custom debt category",
            type: .debt,
            isSelected: true,
            priority: 5
        )
        selectedDebts.insert(newCategory.id)
        showAddDebtForm = false
        newDebtName = ""
    }

    // MARK: - Date Binding and Utilities
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private func binding(for id: UUID) -> Binding<String> {
        return Binding(
            get: { self.debtAmounts[id] ?? "" },
            set: { self.debtAmounts[id] = $0 }
        )
    }

    private func defaultDate() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.month! += 1
        return calendar.date(from: components) ?? Date()
    }

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfMonth(for: Date())
        let endComponents = DateComponents(year: calendar.component(.year, from: start) + 10, month: 12)
        let end = calendar.date(from: endComponents) ?? start
        return start...end
    }

    private func isFormComplete() -> Bool {
        return budgetCategoryStore.categories.filter { selectedDebts.contains($0.id) }.allSatisfy {
            let amount = debtAmounts[$0.id] ?? ""
            return !amount.isEmpty && Double(amount) ?? 0 > 0 && selectedDates[$0.id] != nil
        }
    }
}

// Extension for Calendar to get the start of the month
