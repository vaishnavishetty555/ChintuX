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
    @Published var dayNotes: [DayNoteDTO] = []
    
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
        dayNotes = []
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
                self.dayNotes = []
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

            // Fetch day notes separately so a missing table doesn't block the rest
            do {
                self.dayNotes = try await supabase.fetchDayNotes(forPetIds: petIds)
            } catch {
                self.dayNotes = []
            }

        } catch {
            errorMessage = "Failed to fetch data: \(error.localizedDescription)"
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
        let previous = reminders.first { $0.id == reminder.id }
        do {
            let updated = try await supabase.updateReminder(reminder)
            if let index = reminders.firstIndex(where: { $0.id == updated.id }) {
                reminders[index] = updated
            }

            // Regenerate future instances when recurrence or start date changes.
            let recurrenceChanged = previous?.recurrenceRaw != updated.recurrenceRaw
            let dateChanged = previous?.firstDueAt != updated.firstDueAt
            if recurrenceChanged || dateChanged {
                await regenerateInstances(for: updated)
            }
        } catch {
            errorMessage = "Failed to update reminder: \(error.localizedDescription)"
        }
    }

    /// Deletes future instances and rebuilds them from the current recurrence.
    /// Preserves past instances so completion history isn't lost.
    private func regenerateInstances(for reminder: ReminderDTO) async {
        let now = Date()
        let futureInstances = reminderInstances.filter {
            $0.reminderId == reminder.id && $0.scheduledAt >= now.startOfDay
        }
        for instance in futureInstances {
            do {
                try await supabase.deleteReminderInstance(id: instance.id)
            } catch { /* instance already deleted or not found — safe to ignore */ }
        }
        reminderInstances.removeAll { instance in
            futureInstances.contains { $0.id == instance.id }
        }
        await createReminderInstances(for: reminder)
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

        guard startDate < endDate else { return }

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
            } catch { /* instance creation failed — will retry on next fetchAllData */ }
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
    
    /// Marks the first pending instance of a reminder as completed with the given date.
    /// Creates an instance on the fly if none exists (e.g. legacy reminders).
    func markReminderDone(reminderId: UUID, completedAt: Date) async {
        let instances = reminderInstances(forReminderId: reminderId)
        if let pending = instances.first(where: { $0.statusRaw != "completed" }) {
            let updated = ReminderInstanceDTO(
                id: pending.id,
                reminderId: pending.reminderId,
                scheduledAt: pending.scheduledAt,
                statusRaw: "completed",
                completedAt: completedAt,
                createdAt: pending.createdAt
            )
            do {
                let result = try await supabase.updateReminderInstance(updated)
                if let index = reminderInstances.firstIndex(where: { $0.id == result.id }) {
                    reminderInstances[index] = result
                }
            } catch {
                errorMessage = "Failed to mark visit done: \(error.localizedDescription)"
            }
        } else {
            // No existing instance — create one already completed
            guard let reminder = reminders.first(where: { $0.id == reminderId }) else { return }
            let instance = ReminderInstanceDTO(
                reminderId: reminderId,
                scheduledAt: reminder.firstDueAt,
                statusRaw: "completed",
                completedAt: completedAt
            )
            do {
                let created = try await supabase.createReminderInstance(instance)
                reminderInstances.append(created)
            } catch {
                errorMessage = "Failed to create completed instance: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Log Entries

    func createLogEntry(forPetId petId: UUID, kind: LogKind, detail: String = "", numericValue: Double? = nil, at: Date = .now) async {
        let entry = LogEntryDTO(
            petId: petId,
            kindRaw: kind.rawValue,
            detail: detail,
            numericValue: numericValue,
            at: at
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
    
    func createMoodEntry(forPetId petId: UUID, mood: Mood, note: String = "") async {
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
    
    // MARK: - Pet Activity Helpers (real metrics from stored data)

    /// % of today's reminder instances completed (0–100). Returns nil if no tasks today.
    func wellnessPercent(forPetId petId: UUID) -> Int? {
        let instances = reminderInstancesToday(forPetId: petId)
        guard !instances.isEmpty else { return nil }
        let done = instances.filter { $0.statusRaw == "completed" }.count
        return Int((Double(done) / Double(instances.count)) * 100)
    }

    /// Consecutive days ending today with at least one log entry or completed reminder.
    func streakDays(forPetId petId: UUID) -> Int {
        let cal = Calendar.current
        var streak = 0
        var cursor = Date().startOfDay
        for _ in 0..<90 {
            if hasActivity(forPetId: petId, on: cursor) {
                streak += 1
                cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            } else {
                break
            }
        }
        return streak
    }

    /// Last 7 days' activity flags (oldest first, today last). Used for streak dots.
    func weekActivityDots(forPetId petId: UUID) -> [Bool] {
        let cal = Calendar.current
        let today = Date().startOfDay
        return (0...6).reversed().compactMap { offset -> Bool? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return hasActivity(forPetId: petId, on: day)
        }
    }

    private func hasActivity(forPetId petId: UUID, on dayStart: Date) -> Bool {
        let cal = Calendar.current
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return false }
        let hasLog = logEntries.contains { $0.petId == petId && $0.at >= dayStart && $0.at < dayEnd }
        if hasLog { return true }
        let petReminderIds = Set(reminders.filter { $0.petId == petId }.map(\.id))
        return reminderInstances.contains { instance in
            guard let rid = instance.reminderId, petReminderIds.contains(rid) else { return false }
            let when = instance.completedAt ?? instance.scheduledAt
            return instance.statusRaw == "completed" && when >= dayStart && when < dayEnd
        }
    }

    /// Latest mood the user set for this pet, if any.
    func latestMood(forPetId petId: UUID) -> Mood? {
        let latest = moodEntries
            .filter { $0.petId == petId }
            .max(by: { $0.at < $1.at })
        return Mood(rawValue: latest?.moodRaw ?? "")
    }

    /// Count of today's log entries of a given kind.
    func todayLogCount(forPetId petId: UUID, kind: LogKind) -> Int {
        let start = Date().startOfDay
        let end = Date().endOfDay
        return logEntries.filter {
            $0.petId == petId && $0.kindRaw == kind.rawValue && $0.at >= start && $0.at <= end
        }.count
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
    
    func dayNotes(forDay day: Date, petId: UUID?) -> [DayNoteDTO] {
        let start = day.startOfDay
        let end = day.endOfDay
        return dayNotes.filter {
            $0.day >= start && $0.day <= end && (petId == nil || $0.petId == petId)
        }
    }
    
    func createDayNote(forPetId petId: UUID, day: Date, body: String) async {
        let note = DayNoteDTO(petId: petId, day: day.startOfDay, body: body)
        do {
            let created = try await supabase.createDayNote(note)
            dayNotes.append(created)
        } catch {
            errorMessage = "Failed to create note: \(error.localizedDescription)"
        }
    }
    
    func deleteDayNote(id: UUID) async {
        do {
            try await supabase.deleteDayNote(id: id)
            dayNotes.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete note: \(error.localizedDescription)"
        }
    }
    
    func instances(forDay day: Date) -> [ReminderInstanceDTO] {
        let start = day.startOfDay
        let end = day.endOfDay
        return reminderInstances.filter { $0.scheduledAt >= start && $0.scheduledAt <= end }
    }

    func reminderInstancesToday(forPetId petId: UUID) -> [ReminderInstanceDTO] {
        let start = Date().startOfDay
        let end = Date().endOfDay
        let reminderIds = reminders(forPetId: petId).map(\.id)
        return reminderInstances
            .filter { reminderIds.contains($0.reminderId ?? UUID()) && $0.scheduledAt >= start && $0.scheduledAt <= end }
            .sorted { $0.scheduledAt < $1.scheduledAt }
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
