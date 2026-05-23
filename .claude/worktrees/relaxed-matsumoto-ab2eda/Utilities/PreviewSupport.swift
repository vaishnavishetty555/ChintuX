import SwiftUI
import SwiftData

/// In-memory ModelContainer pre-populated with SeedData for #Preview usage.
@MainActor
enum PreviewSupport {
    static let container: ModelContainer = {
        let schema = Schema([
            Pet.self,
            Reminder.self,
            ReminderInstance.self,
            LogEntry.self,
            MoodEntry.self,
            PetDocument.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            SeedData.seed(into: container.mainContext)
            return container
        } catch {
            fatalError("Preview container init failed: \(error)")
        }
    }()

    static var sharedContext: ModelContext { container.mainContext }

    static let previewPetContext: PetContextStore = {
        let store = PetContextStore()
        // Note: In previews using Supabase, the DataStore will handle pet fetching
        return store
    }()
    
    /// Creates a preview DataStore with sample data
    static var previewDataStore: DataStore {
        let store = DataStore.shared
        // The store will fetch from Supabase when available
        return store
    }
}
