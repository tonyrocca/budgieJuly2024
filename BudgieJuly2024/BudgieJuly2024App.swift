import SwiftUI

@main
struct BudgieJuly2024App: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var budgetCategoryStore = BudgetCategoryStore.shared

    var body: some Scene {
        WindowGroup {
            NavigationView {
                WelcomeView()
                    .environmentObject(budgetCategoryStore)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
