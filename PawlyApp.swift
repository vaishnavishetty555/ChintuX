import SwiftUI
import UserNotifications

@main
struct PawlyApp: App {
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
                .environmentObject(petContext)
                .environmentObject(dataStore)
                .tint(PawlyColors.forest)
                .preferredColorScheme(nil)
                .task {
                    // Ensure anonymous authentication before fetching data
                    await SupabaseConfig.ensureAnonymousSession()
                    await dataStore.fetchAllData()
                }
        }
    }
}
