import SwiftUI

struct GoalSelectionView: View {
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    @Binding var selectedGoalCategories: [BudgetCategory]
    var paymentFrequency: PaymentCadence
    var paycheckAmountText: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Do you have any savings goals?")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 16)
                .padding(.horizontal, 16)

            HStack {
                Button(action: {
                    selectedGoalCategories = budgetCategoryStore.categories.filter { $0.type == .saving }
                }) {
                    Text("Yes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .shadow(radius: 5)
                }

                Button(action: {
                    selectedGoalCategories = []
                }) {
                    Text("No")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .shadow(radius: 5)
                }
            }

            if !selectedGoalCategories.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(selectedGoalCategories) { category in
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
                                    if selectedGoalCategories.contains(where: { $0.id == category.id }) {
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
            }

            Spacer()

            NavigationLink(destination: GoalDetailView(selectedGoalCategories: $selectedGoalCategories, paymentFrequency: paymentFrequency, paycheckAmountText: paycheckAmountText).environmentObject(budgetCategoryStore)) {
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
        if let index = selectedGoalCategories.firstIndex(where: { $0.id == category.id }) {
            selectedGoalCategories.remove(at: index)
        } else {
            selectedGoalCategories.append(category)
        }
    }
}

struct GoalSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        GoalSelectionView(selectedGoalCategories: .constant([]), paymentFrequency: .monthly, paycheckAmountText: "")
            .environmentObject(BudgetCategoryStore.shared)
    }
}
