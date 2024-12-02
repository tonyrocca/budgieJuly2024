import SwiftUI

struct BudgetExperienceQuestionView: View {
    @State private var hasBudgetingExperience: Bool? = nil
    @State private var isInfoExpanded = false
    @EnvironmentObject var budgetCategoryStore: BudgetCategoryStore
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)

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
                    VStack(spacing: 20) {
                        // Yes button
                        Button(action: { hasBudgetingExperience = true }) {
                            NavigationLink(
                                destination: PaymentInputView(hasBudgetingExperience: true).environmentObject(budgetCategoryStore),
                                isActive: Binding(
                                    get: { hasBudgetingExperience == true },
                                    set: { if $0 { hasBudgetingExperience = true } }
                                )
                            ) {
                                Text("Yes, I have my own budget currently")
                                    .font(.headline)
                                    .foregroundColor(hasBudgetingExperience == true ? .white : .primary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(hasBudgetingExperience == true ? customGreen : Color(UIColor.systemGray5))
                                    .cornerRadius(10)
                            }
                        }

                        // No button with recommendation
                        VStack(spacing: 0) {
                            // Recommended banner
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                Text("Recommended for new users")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(customGreen)
                            .cornerRadius(10, corners: [.topLeft, .topRight])

                            // No button
                            Button(action: { hasBudgetingExperience = false }) {
                                NavigationLink(
                                    destination: PaymentInputView(hasBudgetingExperience: false).environmentObject(budgetCategoryStore),
                                    isActive: Binding(
                                        get: { hasBudgetingExperience == false },
                                        set: { if $0 { hasBudgetingExperience = false } }
                                    )
                                ) {
                                    Text("No, I have never budgeted before")
                                        .font(.headline)
                                        .foregroundColor(hasBudgetingExperience == false ? .white : .primary)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(hasBudgetingExperience == false ? customGreen : Color(UIColor.systemGray5))
                                        .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(customGreen, lineWidth: 2)
                        )
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

struct BudgetExperienceQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetExperienceQuestionView()
            .environmentObject(BudgetCategoryStore.shared)
    }
}
