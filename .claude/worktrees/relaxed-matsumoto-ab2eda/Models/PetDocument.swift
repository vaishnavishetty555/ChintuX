import Foundation
import SwiftData

/// PRD — Pet Vault document. Stores encrypted document data with optional OCR
/// text, expiry tracking, and travel-paperwork metadata.
@Model
final class PetDocument {
    @Attribute(.unique) var id: UUID = UUID()
    var pet: Pet?

    var title: String
    var documentTypeRaw: String          // DocumentType.rawValue
    var encryptedData: Data?             // AES-GCM encrypted document bytes
    var thumbnailData: Data?             // unencrypted thumbnail for browsing
    var ocrText: String?                 // extracted text (paid feature)
    var expiryDate: Date?                // for vaccines, licenses, passports
    var notes: String
    var isFavorite: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        pet: Pet? = nil,
        title: String,
        documentType: DocumentType,
        encryptedData: Data? = nil,
        thumbnailData: Data? = nil,
        ocrText: String? = nil,
        expiryDate: Date? = nil,
        notes: String = "",
        isFavorite: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.pet = pet
        self.title = title
        self.documentTypeRaw = documentType.rawValue
        self.encryptedData = encryptedData
        self.thumbnailData = thumbnailData
        self.ocrText = ocrText
        self.expiryDate = expiryDate
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    var documentType: DocumentType {
        DocumentType(rawValue: documentTypeRaw) ?? .other
    }

    /// Returns true if the document is within 30 days of expiry or already expired.
    var isExpiringSoon: Bool {
        guard let expiryDate else { return false }
        return expiryDate.timeIntervalSinceNow < 30 * 24 * 60 * 60
    }

    /// Days until expiry (negative if expired).
    var daysUntilExpiry: Int? {
        guard let expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: expiryDate).day
    }
}
