import SwiftUI
import SwiftData
import UserNotifications

@main
struct PawlyApp: App {
    let modelContainer: ModelContainer
    @StateObject private var petContext = PetContextStore()

    init() {
        do {
            let schema = Schema([
                Pet.self,
                Reminder.self,
                ReminderInstance.self,
                LogEntry.self,
                MoodEntry.self,
                PetDocument.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }

        // Register notification categories with rich actions (PRD §6.3).
        NotificationService.registerCategories()
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(petContext)
                .tint(PawlyColors.forest)
                .preferredColorScheme(nil)
        }
        .modelContainer(modelContainer)
    }
}
