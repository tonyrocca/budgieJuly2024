import SwiftUI

@main
struct BudgieJuly2024App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NavigationView {
                PaymentInputView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
