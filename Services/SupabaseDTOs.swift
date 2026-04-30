import Foundation

// MARK: - Pet DTO

struct PetDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let speciesRaw: String
    let breed: String
    let dateOfBirth: Date?
    let weightKg: Double?
    let sexRaw: String
    let neutered: Bool
    let allergiesText: String
    let ongoingConditionsText: String
    let accentHex: String
    let photoURL: String?
    let statusRaw: String
    let markedPassedAt: Date?
    let markedLostAt: Date?
    let vetName: String
    let vetPhone: String
    let createdAt: Date
    let userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case speciesRaw = "species_raw"
        case breed
        case dateOfBirth = "date_of_birth"
        case weightKg = "weight_kg"
        case sexRaw = "sex_raw"
        case neutered
        case allergiesText = "allergies_text"
        case ongoingConditionsText = "ongoing_conditions_text"
        case accentHex = "accent_hex"
        case photoURL = "photo_url"
        case statusRaw = "status_raw"
        case markedPassedAt = "marked_passed_at"
        case markedLostAt = "marked_lost_at"
        case vetName = "vet_name"
        case vetPhone = "vet_phone"
        case createdAt = "created_at"
        case userId = "user_id"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        speciesRaw: String,
        breed: String = "",
        dateOfBirth: Date? = nil,
        weightKg: Double? = nil,
        sexRaw: String,
        neutered: Bool = false,
        allergiesText: String = "",
        ongoingConditionsText: String = "",
        accentHex: String = "#2D5F4E",
        photoURL: String? = nil,
        statusRaw: String = "active",
        markedPassedAt: Date? = nil,
        markedLostAt: Date? = nil,
        vetName: String = "",
        vetPhone: String = "",
        createdAt: Date = .now,
        userId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.speciesRaw = speciesRaw
        self.breed = breed
        self.dateOfBirth = dateOfBirth
        self.weightKg = weightKg
        self.sexRaw = sexRaw
        self.neutered = neutered
        self.allergiesText = allergiesText
        self.ongoingConditionsText = ongoingConditionsText
        self.accentHex = accentHex
        self.photoURL = photoURL
        self.statusRaw = statusRaw
        self.markedPassedAt = markedPassedAt
        self.markedLostAt = markedLostAt
        self.vetName = vetName
        self.vetPhone = vetPhone
        self.createdAt = createdAt
        self.userId = userId
    }
    
    init(from pet: Pet) {
        self.id = pet.id
        self.name = pet.name
        self.speciesRaw = pet.speciesRaw
        self.breed = pet.breed
        self.dateOfBirth = pet.dateOfBirth
        self.weightKg = pet.weightKg
        self.sexRaw = pet.sexRaw
        self.neutered = pet.neutered
        self.allergiesText = pet.allergiesText
        self.ongoingConditionsText = pet.ongoingConditionsText
        self.accentHex = pet.accentHex
        self.photoURL = nil // Photo is handled separately
        self.statusRaw = pet.statusRaw
        self.markedPassedAt = pet.markedPassedAt
        self.markedLostAt = pet.markedLostAt
        self.vetName = pet.vetName
        self.vetPhone = pet.vetPhone
        self.createdAt = pet.createdAt
        self.userId = nil
    }
}

// MARK: - Reminder DTO

struct ReminderDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let petId: UUID?
    let title: String
    let typeRaw: String
    let dosage: String?
    let recurrenceRaw: String
    let firstDueAt: Date
    let notes: String
    let prescriptionPhotoURL: String?
    let quietStartHour: Int
    let quietEndHour: Int
    let createdAt: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case title
        case typeRaw = "type_raw"
        case dosage
        case recurrenceRaw = "recurrence_raw"
        case firstDueAt = "first_due_at"
        case notes
        case prescriptionPhotoURL = "prescription_photo_url"
        case quietStartHour = "quiet_start_hour"
        case quietEndHour = "quiet_end_hour"
        case createdAt = "created_at"
        case isActive = "is_active"
    }
    
    init(
        id: UUID = UUID(),
        petId: UUID? = nil,
        title: String,
        typeRaw: String,
        dosage: String? = nil,
        recurrenceRaw: String,
        firstDueAt: Date,
        notes: String = "",
        prescriptionPhotoURL: String? = nil,
        quietStartHour: Int = -1,
        quietEndHour: Int = -1,
        createdAt: Date = .now,
        isActive: Bool = true
    ) {
        self.id = id
        self.petId = petId
        self.title = title
        self.typeRaw = typeRaw
        self.dosage = dosage
        self.recurrenceRaw = recurrenceRaw
        self.firstDueAt = firstDueAt
        self.notes = notes
        self.prescriptionPhotoURL = prescriptionPhotoURL
        self.quietStartHour = quietStartHour
        self.quietEndHour = quietEndHour
        self.createdAt = createdAt
        self.isActive = isActive
    }
    
    init(from reminder: Reminder) {
        self.id = reminder.id
        self.petId = reminder.pet?.id
        self.title = reminder.title
        self.typeRaw = reminder.typeRaw
        self.dosage = reminder.dosage
        self.recurrenceRaw = reminder.recurrenceRaw
        self.firstDueAt = reminder.firstDueAt
        self.notes = reminder.notes
        self.prescriptionPhotoURL = nil
        self.quietStartHour = reminder.quietStartHour
        self.quietEndHour = reminder.quietEndHour
        self.createdAt = reminder.createdAt
        self.isActive = reminder.isActive
    }
}

// MARK: - Reminder Instance DTO

struct ReminderInstanceDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let reminderId: UUID?
    let scheduledAt: Date
    let statusRaw: String
    let completedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case reminderId = "reminder_id"
        case scheduledAt = "scheduled_at"
        case statusRaw = "status_raw"
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        reminderId: UUID? = nil,
        scheduledAt: Date,
        statusRaw: String = "upcoming",
        completedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.reminderId = reminderId
        self.scheduledAt = scheduledAt
        self.statusRaw = statusRaw
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
    
    init(from instance: ReminderInstance) {
        self.id = instance.id
        self.reminderId = instance.reminder?.id
        self.scheduledAt = instance.scheduledAt
        self.statusRaw = instance.statusRaw
        self.completedAt = instance.completedAt
        self.createdAt = Date() // Default to now since original model doesn't have createdAt
    }
}

// MARK: - Log Entry DTO

struct LogEntryDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let petId: UUID?
    let kindRaw: String
    let detail: String
    let numericValue: Double?
    let at: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case kindRaw = "kind_raw"
        case detail
        case numericValue = "numeric_value"
        case at
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        petId: UUID? = nil,
        kindRaw: String,
        detail: String = "",
        numericValue: Double? = nil,
        at: Date = .now,
        createdAt: Date = .now
    ) {
        self.id = id
        self.petId = petId
        self.kindRaw = kindRaw
        self.detail = detail
        self.numericValue = numericValue
        self.at = at
        self.createdAt = createdAt
    }
    
    init(from entry: LogEntry) {
        self.id = entry.id
        self.petId = entry.pet?.id
        self.kindRaw = entry.kindRaw
        self.detail = entry.detail
        self.numericValue = entry.numericValue
        self.at = entry.at
        self.createdAt = Date() // Default to now since original model doesn't have createdAt
    }
}

// MARK: - Mood Entry DTO

struct MoodEntryDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let petId: UUID?
    let moodRaw: String
    let note: String
    let at: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case moodRaw = "mood_raw"
        case note
        case at
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        petId: UUID? = nil,
        moodRaw: String,
        note: String = "",
        at: Date = .now,
        createdAt: Date = .now
    ) {
        self.id = id
        self.petId = petId
        self.moodRaw = moodRaw
        self.note = note
        self.at = at
        self.createdAt = createdAt
    }
}

// MARK: - Pet Document DTO

struct PetDocumentDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let petId: UUID?
    let title: String
    let documentTypeRaw: String
    let fileURL: String
    let expiryDate: Date?
    let isEncrypted: Bool
    let ocrText: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case title
        case documentTypeRaw = "document_type_raw"
        case fileURL = "file_url"
        case expiryDate = "expiry_date"
        case isEncrypted = "is_encrypted"
        case ocrText = "ocr_text"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        petId: UUID? = nil,
        title: String,
        documentTypeRaw: String,
        fileURL: String,
        expiryDate: Date? = nil,
        isEncrypted: Bool = false,
        ocrText: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.petId = petId
        self.title = title
        self.documentTypeRaw = documentTypeRaw
        self.fileURL = fileURL
        self.expiryDate = expiryDate
        self.isEncrypted = isEncrypted
        self.ocrText = ocrText
        self.createdAt = createdAt
    }
}
