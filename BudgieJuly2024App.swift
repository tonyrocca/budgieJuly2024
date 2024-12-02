import SwiftUI

struct ColorSchemeModifier: ViewModifier {
    @AppStorage("userInterfaceStyle") private var userInterfaceStyle: UIUserInterfaceStyle = .light
    
    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, userInterfaceStyle == .light ? .light : .dark)
            .preferredColorScheme(userInterfaceStyle == .light ? .light : .dark)
    }
}

extension View {
    func forceLightMode() -> some View {
        self.modifier(ColorSchemeModifier())
    }
}

@main
struct BudgieJuly2024App: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var budgetCategoryStore = BudgetCategoryStore.shared

    init() {
        // Force light mode at app launch
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                WelcomeView()
                    .environmentObject(budgetCategoryStore)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .forceLightMode()
            }
        }
    }
}
