import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import UserNotifications

@main
struct BachatApp: App {
    let container: ModelContainer

    init() {
        FirebaseApp.configure()
        
        #if targetEnvironment(simulator)
        try? Auth.auth().useUserAccessGroup(nil)
        #endif
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        
        do {
            let schema = Schema([
                IncomeEntry.self,
                MonthlyIncome.self,
                BudgetConfig.self,
                CategoryBudget.self,
                SavingsGoal.self,
                AccountBalance.self,
                SalaryAction.self,
                UserSettings.self,
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    @StateObject private var authManager = AuthManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(container)
    }
}
