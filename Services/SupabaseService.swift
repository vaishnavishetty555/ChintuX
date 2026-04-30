import Foundation
import Supabase

/// Main service for Supabase database operations
@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client = SupabaseConfig.client
    
    // MARK: - Pets
    
    func fetchPets() async throws -> [PetDTO] {
        let response = try await client
            .from("pets")
            .select("""
                id, name, species_raw, breed, date_of_birth, weight_kg, 
                sex_raw, neutered, allergies_text, ongoing_conditions_text,
                accent_hex, photo_url, status_raw, marked_passed_at, 
                marked_lost_at, vet_name, vet_phone, created_at, user_id
            """)
            .eq("status_raw", value: "active")
            .order("created_at", ascending: true)
            .execute()
        
        return try JSONDecoder().decode([PetDTO].self, from: response.data)
    }
    
    func createPet(_ pet: PetDTO) async throws -> PetDTO {
        let response = try await client
            .from("pets")
            .insert(pet)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(PetDTO.self, from: response.data)
    }
    
    func updatePet(_ pet: PetDTO) async throws -> PetDTO {
        let response = try await client
            .from("pets")
            .update(pet)
            .eq("id", value: pet.id)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(PetDTO.self, from: response.data)
    }
    
    func deletePet(id: UUID) async throws {
        try await client
            .from("pets")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Reminders
    
    func fetchReminders(forPetId petId: UUID? = nil) async throws -> [ReminderDTO] {
        var query = client
            .from("reminders")
            .select("""
                id, pet_id, title, type_raw, dosage, recurrence_raw,
                first_due_at, notes, prescription_photo_url, quiet_start_hour,
                quiet_end_hour, created_at, is_active
            """)
        
        if let petId = petId {
            query = query.eq("pet_id", value: petId)
        }
        
        let response = try await query
            .eq("is_active", value: true)
            .order("first_due_at", ascending: true)
            .execute()
        
        return try JSONDecoder().decode([ReminderDTO].self, from: response.data)
    }
    
    func createReminder(_ reminder: ReminderDTO) async throws -> ReminderDTO {
        let response = try await client
            .from("reminders")
            .insert(reminder)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(ReminderDTO.self, from: response.data)
    }
    
    func updateReminder(_ reminder: ReminderDTO) async throws -> ReminderDTO {
        let response = try await client
            .from("reminders")
            .update(reminder)
            .eq("id", value: reminder.id)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(ReminderDTO.self, from: response.data)
    }
    
    func deleteReminder(id: UUID) async throws {
        try await client
            .from("reminders")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Reminder Instances
    
    func fetchReminderInstances(forReminderId reminderId: UUID? = nil) async throws -> [ReminderInstanceDTO] {
        var query = client
            .from("reminder_instances")
            .select("id, reminder_id, scheduled_at, status_raw, completed_at, created_at")
        
        if let reminderId = reminderId {
            query = query.eq("reminder_id", value: reminderId)
        }
        
        let response = try await query
            .order("scheduled_at", ascending: true)
            .execute()
        
        return try JSONDecoder().decode([ReminderInstanceDTO].self, from: response.data)
    }
    
    func createReminderInstance(_ instance: ReminderInstanceDTO) async throws -> ReminderInstanceDTO {
        let response = try await client
            .from("reminder_instances")
            .insert(instance)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(ReminderInstanceDTO.self, from: response.data)
    }
    
    func updateReminderInstance(_ instance: ReminderInstanceDTO) async throws -> ReminderInstanceDTO {
        let response = try await client
            .from("reminder_instances")
            .update(instance)
            .eq("id", value: instance.id)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(ReminderInstanceDTO.self, from: response.data)
    }
    
    // MARK: - Log Entries
    
    func fetchLogEntries(forPetId petId: UUID? = nil) async throws -> [LogEntryDTO] {
        var query = client
            .from("log_entries")
            .select("id, pet_id, kind_raw, detail, numeric_value, at, created_at")
        
        if let petId = petId {
            query = query.eq("pet_id", value: petId)
        }
        
        let response = try await query
            .order("at", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([LogEntryDTO].self, from: response.data)
    }
    
    func createLogEntry(_ entry: LogEntryDTO) async throws -> LogEntryDTO {
        let response = try await client
            .from("log_entries")
            .insert(entry)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(LogEntryDTO.self, from: response.data)
    }
    
    func deleteLogEntry(id: UUID) async throws {
        try await client
            .from("log_entries")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Mood Entries
    
    func fetchMoodEntries(forPetId petId: UUID? = nil) async throws -> [MoodEntryDTO] {
        var query = client
            .from("mood_entries")
            .select("id, pet_id, mood_raw, note, at, created_at")
        
        if let petId = petId {
            query = query.eq("pet_id", value: petId)
        }
        
        let response = try await query
            .order("at", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([MoodEntryDTO].self, from: response.data)
    }
    
    func createMoodEntry(_ entry: MoodEntryDTO) async throws -> MoodEntryDTO {
        let response = try await client
            .from("mood_entries")
            .insert(entry)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(MoodEntryDTO.self, from: response.data)
    }
    
    // MARK: - Documents
    
    func fetchDocuments(forPetId petId: UUID? = nil) async throws -> [PetDocumentDTO] {
        var query = client
            .from("pet_documents")
            .select("""
                id, pet_id, title, document_type_raw, file_url, 
                expiry_date, is_encrypted, ocr_text, created_at
            """)
        
        if let petId = petId {
            query = query.eq("pet_id", value: petId)
        }
        
        let response = try await query
            .order("created_at", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([PetDocumentDTO].self, from: response.data)
    }
    
    func createDocument(_ document: PetDocumentDTO) async throws -> PetDocumentDTO {
        let response = try await client
            .from("pet_documents")
            .insert(document)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(PetDocumentDTO.self, from: response.data)
    }
    
    func deleteDocument(id: UUID) async throws {
        try await client
            .from("pet_documents")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - File Storage
    
    func uploadFile(data: Data, path: String, contentType: String = "image/jpeg") async throws -> String {
        try await client.storage
            .from("pet-files")
            .upload(path: path, file: data, options: FileOptions(contentType: contentType))
        
        let publicURL = try client.storage
            .from("pet-files")
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
    
    func deleteFile(path: String) async throws {
        try await client.storage
            .from("pet-files")
            .remove(paths: [path])
    }
}
