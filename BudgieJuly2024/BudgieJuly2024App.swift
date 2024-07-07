import SwiftUI

@main
struct BudgieJuly2024App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(paymentFrequency: .monthly, paycheckAmountText: "")
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
