import Foundation

enum Species: String, Codable, CaseIterable, Identifiable {
    case dog, cat, rabbit, bird
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dog:    return "Dog"
        case .cat:    return "Cat"
        case .rabbit: return "Rabbit"
        case .bird:   return "Bird"
        }
    }

    /// SF Symbol used as a stand-in for the PRD's custom line icons.
    var sfSymbol: String {
        switch self {
        case .dog:    return "pawprint.fill"
        case .cat:    return "pawprint"
        case .rabbit: return "hare.fill"
        case .bird:   return "bird.fill"
        }
    }

    /// Partial list of breeds per species (good enough for a searchable picker
    /// in onboarding). Extend freely later.
    var breeds: [String] {
        switch self {
        case .dog:
            return ["Mixed", "Indian Pariah", "Labrador", "Golden Retriever", "Beagle",
                    "Pug", "Shih Tzu", "German Shepherd", "Pomeranian", "Rottweiler",
                    "Cocker Spaniel", "Doberman", "Dachshund", "Siberian Husky"]
        case .cat:
            return ["Mixed", "Indian Billi", "Persian", "Siamese", "Bombay",
                    "Maine Coon", "Ragdoll", "British Shorthair", "Bengal",
                    "Scottish Fold", "Sphynx"]
        case .rabbit:
            return ["Mixed", "Holland Lop", "Netherland Dwarf", "Mini Lop", "Flemish Giant"]
        case .bird:
            return ["Mixed", "Budgerigar", "Cockatiel", "Indian Ringneck",
                    "Lovebird", "Canary", "Finch"]
        }
    }
}

enum PetSex: String, Codable, CaseIterable, Identifiable {
    case male, female, unknown
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .male:    return "Male"
        case .female:  return "Female"
        case .unknown: return "Unknown"
        }
    }
}

enum PetStatus: String, Codable, CaseIterable {
    case active, passed, lost
}
