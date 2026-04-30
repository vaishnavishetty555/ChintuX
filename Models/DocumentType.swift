import Foundation

/// Document types supported by the Pet Vault.
enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case vaccinationCertificate
    case microchipDetails
    case vetBill
    case insurance
    case breederPapers
    case petPassport
    case license
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vaccinationCertificate: return "Vaccination Certificate"
        case .microchipDetails:       return "Microchip Details"
        case .vetBill:                return "Vet Bill"
        case .insurance:              return "Insurance"
        case .breederPapers:          return "Breeder Papers"
        case .petPassport:            return "Pet Passport"
        case .license:                return "License"
        case .other:                  return "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .vaccinationCertificate: return "syringe.fill"
        case .microchipDetails:       return "cpu.fill"
        case .vetBill:                return "doc.text.fill"
        case .insurance:              return "shield.fill"
        case .breederPapers:          return "person.2.fill"
        case .petPassport:            return "airplane"
        case .license:                return "checkmark.seal.fill"
        case .other:                  return "doc.fill"
        }
    }

    /// Whether this document type typically has an expiry date.
    var hasExpiry: Bool {
        switch self {
        case .vaccinationCertificate, .petPassport, .license:
            return true
        default:
            return false
        }
    }
}
