import SwiftUI

struct WelcomeView: View {
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    @State private var showWelcomeText = false
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                // Title
                Text("Deep Pockets")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(showWelcomeText ? 1 : 0)
                    .offset(y: showWelcomeText ? 0 : 20)
                
                // Bullet points
                VStack(alignment: .leading, spacing: 16) {
                    bulletPoint(text: "This is an early version of a credit focused budgeting app")
                    bulletPoint(text: "The goal of the app is to let users know what they can or can't afford. This is achieved by building a proactive budget.")
                    bulletPoint(text: "The app will let you know whether you are spending too little or too much. It will help nudge you to save for things that you are not aware of")
                    bulletPoint(text: "The end goal is reduce the stress around affordability, and give users ease of mind that they 'can' afford that big purchase, and if not we will help you get there")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
                .opacity(showWelcomeText ? 1 : 0)
                .offset(y: showWelcomeText ? 0 : 20)
                
                Spacer()
                
                // Get Started Button
                NavigationLink(destination: BudgetExperienceQuestionView().environmentObject(BudgetCategoryStore.shared)) {
                    HStack {
                        Text("Get Started")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(customGreen)
                    .cornerRadius(15)
                    .shadow(color: customGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showWelcomeText ? 1 : 0)
                .offset(y: showWelcomeText ? 0 : 20)
            }
            .background(Color.white)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showWelcomeText = true
            }
        }
    }
    
    private func bulletPoint(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("•")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(customGreen)
            
            Text(text)
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
