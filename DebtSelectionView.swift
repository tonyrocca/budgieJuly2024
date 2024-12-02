import SwiftUI

struct DebtSelectionView: View {
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    private let lightGreen = Color(red: 0.0, green: 0.27, blue: 0.0).opacity(0.1)
    
    @Binding var income: String
    @Binding var paymentFrequency: PaymentCadence
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @State private var selectedDebtCategories: [UUID] = []
    @State private var showAddDebtForm = false
    @State private var newDebtName = ""
    var hasExpenses: Bool
    var hasSavingsGoals: Bool
    var hasBudgetingExperience: Bool

    var body: some View {
        ZStack {  // Wrap everything in a ZStack to properly layer the modal
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select your debt categories")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Choose the debt you currently are paying off.")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.horizontal, 16)

                // Categories
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 0) {
                            // All Debts Section Header
                            HStack {
                                Text("💰")
                                Text("Your Debts")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(lightGreen)

                            // Debt Categories List
                            VStack(spacing: 0) {
                                ForEach(budgetCategoryStore.categories.filter { $0.type == .debt }, id: \.id) { category in
                                    VStack(spacing: 0) {
                                        ToggleRow(
                                            isOn: Binding(
                                                get: { selectedDebtCategories.contains(category.id) },
                                                set: { newValue in
                                                    if newValue {
                                                        selectedDebtCategories.append(category.id)
                                                        if let index = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                                            budgetCategoryStore.categories[index].isSelected = true
                                                        }
                                                    } else {
                                                        if let index = selectedDebtCategories.firstIndex(of: category.id) {
                                                            selectedDebtCategories.remove(at: index)
                                                            if let catIndex = budgetCategoryStore.categories.firstIndex(where: { $0.id == category.id }) {
                                                                budgetCategoryStore.categories[catIndex].isSelected = false
                                                            }
                                                        }
                                                    }
                                                }
                                            ),
                                            icon: category.emoji,
                                            text: category.name
                                        )
                                        
                                        if category.id != budgetCategoryStore.categories.filter({ $0.type == .debt }).last?.id {
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }

                                // Add Category Button
                                Button(action: { showAddDebtForm = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(customGreen)
                                        Text("Add Category")
                                            .foregroundColor(customGreen)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()

                // Next Button
                NavigationLink(destination: DebtDetailView(
                    income: $income,
                    paymentFrequency: $paymentFrequency,
                    hasExpenses: hasExpenses,
                    hasSavings: hasSavingsGoals,
                    hasBudgetingExperience: hasBudgetingExperience
                ).environmentObject(budgetCategoryStore)) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(customGreen)
                        .cornerRadius(10)
                        .shadow(color: customGreen.opacity(0.3), radius: 5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 50)
                .disabled(selectedDebtCategories.isEmpty)
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))

            // Modal overlay
            if showAddDebtForm {
                AddDebtCategoryModal(
                    isPresented: $showAddDebtForm,
                    newDebtName: $newDebtName,
                    onAdd: addDebtCategory
                )
            }
        }
    }
    
    private var addDebtFormSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Category Name", text: $newDebtName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: addDebtCategory) {
                    Text("Add")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(customGreen)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(newDebtName.isEmpty)
                .opacity(newDebtName.isEmpty ? 0.6 : 1.0)
            }
            .padding(.top, 20)
            .navigationBarTitle("Add New Debt Category", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    showAddDebtForm = false
                }
            )
        }
    }

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
        selectedDebtCategories.append(newCategory.id)
        showAddDebtForm = false
        newDebtName = ""
    }
}

struct CustomToggleStyle: ToggleStyle {
    let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(configuration.isOn ? customGreen : Color(UIColor.systemGray5))
                .frame(width: 50, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .offset(x: configuration.isOn ? 11 : -11)
                )
                .animation(.spring(response: 0.2, dampingFraction: 0.9), value: configuration.isOn)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct AddDebtCategoryModal: View {
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    @Binding var isPresented: Bool
    @Binding var newDebtName: String
    let onAdd: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            // Modal content
            VStack(spacing: 24) {
                // Header with close button
                HStack {
                    Text("Add New Debt")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                
                // Icon and description
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(customGreen)
                    
                    Text("Enter the name of your debt category")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Text field
                TextField("Debt Category Name", text: $newDebtName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                
                // Add button
                Button(action: {
                    onAdd()
                    isPresented = false
                }) {
                    Text("Add Category")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(customGreen)
                        .cornerRadius(10)
                }
                .disabled(newDebtName.isEmpty)
                .opacity(newDebtName.isEmpty ? 0.6 : 1.0)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10)
            .padding(.horizontal, 40)
        }
    }
}

struct ToggleRow: View {
    @Binding var isOn: Bool
    let icon: String
    let text: String

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Text(icon)
                Text(text)
                    .font(.body)
            }
        }
        .toggleStyle(CustomToggleStyle())
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct DebtSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DebtSelectionView(
            income: .constant("5000"),
            paymentFrequency: .constant(.monthly),
            hasExpenses: true,
            hasSavingsGoals: true,
            hasBudgetingExperience: true  // Added this line to the preview
        )
        .environmentObject(BudgetCategoryStore.shared)
    }
}

struct DebtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DebtDetailView(
            income: .constant("5000"),
            paymentFrequency: .constant(.monthly),
            hasExpenses: true,
            hasSavings: true,
            hasBudgetingExperience: true  // Added this line to the preview
        )
        .environmentObject(BudgetCategoryStore.shared)
    }
}
