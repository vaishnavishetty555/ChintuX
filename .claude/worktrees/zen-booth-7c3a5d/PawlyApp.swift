import SwiftUI
import SwiftData
import UserNotifications

@main
struct PawlyApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var petContext = PetContextStore()
    @StateObject private var dataStore = DataStore.shared

    init() {
        // Register notification categories with rich actions (PRD §6.3).
        NotificationService.registerCategories()
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(petContext)
                .environmentObject(dataStore)
                .tint(PawlyColors.forest)
                .preferredColorScheme(nil)
                .onOpenURL { url in
                    authService.handleDeepLink(url)
                }
                .sheet(isPresented: Binding(
                    get: { authService.isInPasswordRecovery },
                    set: { if !$0 { authService.isInPasswordRecovery = false } }
                )) {
                    SetNewPasswordView()
                        .environmentObject(authService)
                }
        }
        .modelContainer(for: [
            Pet.self,
            Reminder.self,
            ReminderInstance.self,
            LogEntry.self,
            MoodEntry.self,
            PetDocument.self,
        ])
    }
}
