import SwiftUI

struct LoadingView<NextView: View>: View {
    let nextDestination: NextView
    @State private var progress: CGFloat = 0.0
    @State private var showNextButton = false
    @State private var currentStepIndex = 0
    @State private var completedSteps: Set<Int> = []
    
    private let customGreen = Color(red: 0.0, green: 0.27, blue: 0.0)
    
    private let steps = [
        LoadingStep(
            icon: "📊",
            title: "Building Foundation",
            description: "Setting up your budget..."
        ),
        LoadingStep(
            icon: "🎯",
            title: "Personalizing Plan",
            description: "Customizing for your profile..."
        ),
        LoadingStep(
            icon: "✨",
            title: "Fine-tuning",
            description: "Optimizing your budget..."
        )
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Personalized Budget")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Creating a tailored financial plan")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.horizontal, 16)
            
            // Progress indicator and bar
            VStack(spacing: 8) {
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(customGreen)
                    Spacer()
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(customGreen)
                        .frame(width: UIScreen.main.bounds.width * 0.9 * progress, height: 8)
                }
            }
            .padding(.horizontal, 16)
            
            // Steps list
            VStack(spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    LoadingStepView(
                        step: step,
                        isActive: currentStepIndex == index,
                        isCompleted: completedSteps.contains(index),
                        customGreen: customGreen
                    )
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Next button
            if showNextButton {
                NavigationLink(destination: nextDestination) {
                    Text("View Your Budget")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(customGreen)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: NavigationLink(destination: nextDestination) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.blue)
        })
        .onAppear {
            startLoading()
        }
    }
    
    private func startLoading() {
        // Smooth progress animation
        let totalDuration: Double = 7.0
        let updateInterval: Double = 0.05
        let totalSteps = Int(totalDuration / updateInterval)
        
        for step in 0...totalSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * updateInterval) {
                withAnimation(.linear(duration: updateInterval)) {
                    progress = min(CGFloat(step) / CGFloat(totalSteps), 1.0)
                    
                    // Update current step based on progress
                    let newStepIndex = Int(progress * CGFloat(steps.count))
                    if newStepIndex != currentStepIndex && newStepIndex < steps.count {
                        currentStepIndex = newStepIndex
                        if newStepIndex > 0 {
                            completedSteps.insert(newStepIndex - 1)
                        }
                    }
                }
            }
        }
        
        // Show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            withAnimation {
                completedSteps.insert(steps.count - 1)
                showNextButton = true
            }
        }
    }
}

struct LoadingStepView: View {
    let step: LoadingStep
    let isActive: Bool
    let isCompleted: Bool
    let customGreen: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isCompleted ? customGreen.opacity(0.2) :
                            isActive ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(step.icon)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                    .foregroundColor(isActive ? .primary : .secondary)
                
                Text(step.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(customGreen)
                    .imageScale(.large)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .opacity(isActive || isCompleted ? 1 : 0.5)
    }
}

struct LoadingStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}
