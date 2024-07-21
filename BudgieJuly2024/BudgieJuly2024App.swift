import SwiftUI

@main
struct BudgieJuly2024App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NavigationView {
                WelcomeView()
                    .environmentObject(BudgetCategoryStore.shared)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
