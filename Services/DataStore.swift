import Foundation
import SwiftUI
import SwiftData

/// Main data store that manages app state and syncs with Supabase
@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()
    
    private let supabase = SupabaseService.shared
    
    // MARK: - Published Properties
    
    @Published var pets: [PetDTO] = []
    @Published var reminders: [ReminderDTO] = []
    @Published var reminderInstances: [ReminderInstanceDTO] = []
    @Published var logEntries: [LogEntryDTO] = []
    @Published var moodEntries: [MoodEntryDTO] = []
    @Published var documents: [PetDocumentDTO] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Clear
    
    func clear() {
        pets = []
        reminders = []
        reminderInstances = []
        logEntries = []
        moodEntries = []
        documents = []
        errorMessage = nil
    }
    
    // MARK: - Fetch All Data
    
    func fetchAllData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch pets scoped to the authenticated user first
            let fetchedPets = try await supabase.fetchPets()
            self.pets = fetchedPets
            
            let petIds = fetchedPets.map(\.id)
            
            guard !petIds.isEmpty else {
                // No pets — clear everything else so we don't show stale data
                self.reminders = []
                self.reminderInstances = []
                self.logEntries = []
                self.moodEntries = []
                self.documents = []
                return
            }
            
            // Fetch reminders for this user's pets
            let fetchedReminders = try await supabase.fetchReminders(forPetIds: petIds)
            self.reminders = fetchedReminders
            
            let reminderIds = fetchedReminders.map(\.id)
            
            // Parallel fetch of instances, logs, moods, docs
            async let instancesTask = supabase.fetchReminderInstances(forReminderIds: reminderIds)
            async let logsTask = supabase.fetchLogEntries(forPetIds: petIds)
            async let moodsTask = supabase.fetchMoodEntries(forPetIds: petIds)
            async let docsTask = supabase.fetchDocuments(forPetIds: petIds)
            
            let (fetchedInstances, fetchedLogs, fetchedMoods, fetchedDocs) = try await (
                instancesTask,
                logsTask,
                moodsTask,
                docsTask
            )
            
            self.reminderInstances = fetchedInstances
            self.logEntries = fetchedLogs
            self.moodEntries = fetchedMoods
            self.documents = fetchedDocs
            
        } catch {
            errorMessage = "Failed to fetch data: \(error.localizedDescription)"
            print("Error fetching data: \(error)")
        }
    }
    
    // MARK: - Pets
    
    func createPet(name: String, species: Species, breed: String = "", dateOfBirth: Date? = nil, sex: PetSex = .unknown, accentHex: String = "#2D5F4E") async -> PetDTO? {
        let pet = PetDTO(
            name: name,
            speciesRaw: species.rawValue,
            breed: breed,
            dateOfBirth: dateOfBirth,
            sexRaw: sex.rawValue,
            accentHex: accentHex,
            userId: AuthService.shared.userId
        )
        
        do {
            let created = try await supabase.createPet(pet)
            pets.append(created)
            return created
        } catch {
            errorMessage = "Failed to create pet: \(error.localizedDescription)"
            print("DEBUG: Failed to create pet with error: \(error)")
            if let nsError = error as NSError? {
                print("DEBUG: Error domain: \(nsError.domain), code: \(nsError.code)")
                print("DEBUG: Error userInfo: \(nsError.userInfo)")
            }
            return nil
        }
    }
    
    func updatePet(_ pet: PetDTO) async {
        do {
            let updated = try await supabase.updatePet(pet)
            if let index = pets.firstIndex(where: { $0.id == updated.id }) {
                pets[index] = updated
            }
        } catch {
            errorMessage = "Failed to update pet: \(error.localizedDescription)"
        }
    }
    
    func deletePet(id: UUID) async {
        do {
            try await supabase.deletePet(id: id)
            pets.removeAll { $0.id == id }
            reminders.removeAll { $0.petId == id }
            logEntries.removeAll { $0.petId == id }
            moodEntries.removeAll { $0.petId == id }
        } catch {
            errorMessage = "Failed to delete pet: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reminders
    
    func createReminder(forPetId petId: UUID, title: String, type: ReminderType, recurrence: Recurrence, firstDueAt: Date, dosage: String? = nil, notes: String = "") async {
        let reminder = ReminderDTO(
            petId: petId,
            title: title,
            typeRaw: type.rawValue,
            dosage: dosage,
            recurrenceRaw: recurrence.rawString,
            firstDueAt: firstDueAt,
            notes: notes
        )
        
        do {
            let created = try await supabase.createReminder(reminder)
            reminders.append(created)
            
            // Create instances based on recurrence
            await createReminderInstances(for: created)
        } catch {
            errorMessage = "Failed to create reminder: \(error.localizedDescription)"
        }
    }
    
    func updateReminder(_ reminder: ReminderDTO) async {
        do {
            let updated = try await supabase.updateReminder(reminder)
            if let index = reminders.firstIndex(where: { $0.id == updated.id }) {
                reminders[index] = updated
            }
        } catch {
            errorMessage = "Failed to update reminder: \(error.localizedDescription)"
        }
    }
    
    func deleteReminder(id: UUID) async {
        do {
            try await supabase.deleteReminder(id: id)
            reminders.removeAll { $0.id == id }
            reminderInstances.removeAll { $0.reminderId == id }
        } catch {
            errorMessage = "Failed to delete reminder: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reminder Instances
    
    private func createReminderInstances(for reminder: ReminderDTO) async {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 120, to: .now) ?? .now
        let startDate = max(reminder.firstDueAt, Date().addingTimeInterval(-60))
        
        let recurrence = Recurrence(rawString: reminder.recurrenceRaw) ?? .once
        
        let dates = RecurrenceEngine.occurrences(
            recurrence: recurrence,
            firstDueAt: reminder.firstDueAt,
            in: startDate..<endDate
        )
        
        for date in dates {
            let instance = ReminderInstanceDTO(
                reminderId: reminder.id,
                scheduledAt: date
            )
            
            do {
                let created = try await supabase.createReminderInstance(instance)
                reminderInstances.append(created)
            } catch {
                print("Failed to create instance: \(error)")
            }
        }
    }
    
    func toggleReminderInstance(_ instance: ReminderInstanceDTO) async {
        let newStatus: String
        let completedAt: Date?
        
        if instance.statusRaw == "completed" {
            newStatus = "upcoming"
            completedAt = nil
        } else {
            newStatus = "completed"
            completedAt = .now
        }
        
        let updated = ReminderInstanceDTO(
            id: instance.id,
            reminderId: instance.reminderId,
            scheduledAt: instance.scheduledAt,
            statusRaw: newStatus,
            completedAt: completedAt,
            createdAt: instance.createdAt
        )
        
        do {
            let result = try await supabase.updateReminderInstance(updated)
            if let index = reminderInstances.firstIndex(where: { $0.id == result.id }) {
                reminderInstances[index] = result
            }
        } catch {
            errorMessage = "Failed to update instance: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Log Entries
    
    func createLogEntry(forPetId petId: UUID, kind: LogKind, detail: String = "", numericValue: Double? = nil) async {
        let entry = LogEntryDTO(
            petId: petId,
            kindRaw: kind.rawValue,
            detail: detail,
            numericValue: numericValue
        )
        
        do {
            let created = try await supabase.createLogEntry(entry)
            logEntries.insert(created, at: 0)
            
            // Update pet weight if applicable
            if kind == .weight, let weight = numericValue {
                if let petIndex = pets.firstIndex(where: { $0.id == petId }) {
                    var updatedPet = pets[petIndex]
                    updatedPet = PetDTO(
                        id: updatedPet.id,
                        name: updatedPet.name,
                        speciesRaw: updatedPet.speciesRaw,
                        breed: updatedPet.breed,
                        dateOfBirth: updatedPet.dateOfBirth,
                        weightKg: weight,
                        sexRaw: updatedPet.sexRaw,
                        neutered: updatedPet.neutered,
                        allergiesText: updatedPet.allergiesText,
                        ongoingConditionsText: updatedPet.ongoingConditionsText,
                        accentHex: updatedPet.accentHex,
                        photoURL: updatedPet.photoURL,
                        statusRaw: updatedPet.statusRaw,
                        markedPassedAt: updatedPet.markedPassedAt,
                        markedLostAt: updatedPet.markedLostAt,
                        vetName: updatedPet.vetName,
                        vetPhone: updatedPet.vetPhone,
                        createdAt: updatedPet.createdAt,
                        userId: updatedPet.userId
                    )
                    await updatePet(updatedPet)
                }
            }
        } catch {
            errorMessage = "Failed to create log entry: \(error.localizedDescription)"
        }
    }
    
    func deleteLogEntry(id: UUID) async {
        do {
            try await supabase.deleteLogEntry(id: id)
            logEntries.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete log entry: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Mood Entries
    
    func createMoodEntry(forPetId petId: UUID, mood: MoodType, note: String = "") async {
        let entry = MoodEntryDTO(
            petId: petId,
            moodRaw: mood.rawValue,
            note: note
        )
        
        do {
            let created = try await supabase.createMoodEntry(entry)
            moodEntries.insert(created, at: 0)
        } catch {
            errorMessage = "Failed to create mood entry: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    
    func reminders(forPetId petId: UUID) -> [ReminderDTO] {
        reminders.filter { $0.petId == petId }
    }
    
    func reminderInstances(forReminderId reminderId: UUID) -> [ReminderInstanceDTO] {
        reminderInstances.filter { $0.reminderId == reminderId }
    }
    
    func logEntries(forPetId petId: UUID) -> [LogEntryDTO] {
        logEntries.filter { $0.petId == petId }
    }
    
    func moodEntries(forPetId petId: UUID) -> [MoodEntryDTO] {
        moodEntries.filter { $0.petId == petId }
    }
    
    func documents(forPetId petId: UUID) -> [PetDocumentDTO] {
        documents.filter { $0.petId == petId }
    }
    
    func instances(forDay day: Date) -> [ReminderInstanceDTO] {
        let start = day.startOfDay
        let end = day.endOfDay
        return reminderInstances.filter { $0.scheduledAt >= start && $0.scheduledAt <= end }
    }
}

// MARK: - Mood Type

enum MoodType: String, Codable, CaseIterable, Identifiable {
    case happy = "happy"
    case calm = "calm"
    case energetic = "energetic"
    case tired = "tired"
    case anxious = "anxious"
    case sad = "sad"
    case angry = "angry"
    case sick = "sick"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .happy: return "Happy"
        case .calm: return "Calm"
        case .energetic: return "Energetic"
        case .tired: return "Tired"
        case .anxious: return "Anxious"
        case .sad: return "Sad"
        case .angry: return "Angry"
        case .sick: return "Sick"
        }
    }
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .calm: return "😌"
        case .energetic: return "⚡️"
        case .tired: return "😴"
        case .anxious: return "😰"
        case .sad: return "😢"
        case .angry: return "😠"
        case .sick: return "🤒"
        }
    }
}
