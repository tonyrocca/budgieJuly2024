import SwiftUI

// MARK: - BudgetExperienceQuestionView
struct BudgetExperienceQuestionView: View {
    @State private var hasBudgetingExperience: Bool? = nil
    @State private var isInfoExpanded = false
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Do you currently budget?")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Select whether you have experience with budgeting.")
                            .font(.headline)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                    // Yes/No Buttons
                    VStack(spacing: 16) {
                        NavigationLink(
                            destination: PaymentInputView(hasBudgetingExperience: true).environmentObject(budgetCategoryStore),
                            tag: true,
                            selection: $hasBudgetingExperience
                        ) {
                            Button(action: { hasBudgetingExperience = true }) {
                                Text("Yes, I have my own budget currently")
                                    .font(.headline)
                                    .foregroundColor(hasBudgetingExperience == true ? .white : .primary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(hasBudgetingExperience == true ? Color.blue : Color(UIColor.systemGray5))
                                    .cornerRadius(10)
                            }
                        }

                        NavigationLink(
                            destination: PaymentInputView(hasBudgetingExperience: false).environmentObject(budgetCategoryStore),
                            tag: false,
                            selection: $hasBudgetingExperience
                        ) {
                            Button(action: { hasBudgetingExperience = false }) {
                                Text("No, I have never budgeted before")
                                    .font(.headline)
                                    .foregroundColor(hasBudgetingExperience == false ? .white : .primary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(hasBudgetingExperience == false ? Color.blue : Color(UIColor.systemGray5))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Information Dropdown
                    infoDropdown
                }
            }
            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(false)
        .onAppear {
            hasBudgetingExperience = nil
        }
    }

    private var infoDropdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isInfoExpanded.toggle()
                }
            }) {
                HStack {
                    Text("What is Budgeting?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: isInfoExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)

            if isInfoExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Budgeting is the process of creating a plan to spend your money.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Benefits of budgeting include:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Better control of your finances")
                        bulletPoint("Ability to save for future goals")
                        bulletPoint("Reduced financial stress")
                        bulletPoint("Improved decision-making about spending")
                    }

                    Text("Whether you're new to budgeting or have experience, this app will help you create and maintain a personalized budget tailored to your needs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .transition(.opacity)
            }
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
struct BudgetExperienceQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetExperienceQuestionView()
            .environmentObject(BudgetCategoryStore.shared)
    }
}
