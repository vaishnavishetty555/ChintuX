import Foundation

enum Species: String, Codable, CaseIterable, Identifiable {
    // Common companions
    case dog, cat, rabbit, bird, fish, hamster, horse
    // Reptiles & amphibians
    case snake, lizard, turtle, frog
    // Exotic small pets
    case guinea_pig, ferret, hedgehog, chinchilla
    // Farm & more
    case goat, sheep, pig, chicken

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dog:        return "Dog"
        case .cat:        return "Cat"
        case .rabbit:     return "Rabbit"
        case .bird:       return "Bird"
        case .fish:       return "Fish"
        case .hamster:    return "Hamster"
        case .horse:      return "Horse"
        case .snake:      return "Snake"
        case .lizard:     return "Lizard"
        case .turtle:     return "Turtle"
        case .frog:       return "Frog"
        case .guinea_pig: return "Guinea Pig"
        case .ferret:     return "Ferret"
        case .hedgehog:   return "Hedgehog"
        case .chinchilla: return "Chinchilla"
        case .goat:       return "Goat"
        case .sheep:      return "Sheep"
        case .pig:        return "Pig"
        case .chicken:    return "Chicken"
        }
    }

    /// Emoji representation for visual identity.
    var emoji: String {
        switch self {
        case .dog:        return "🐕"
        case .cat:        return "🐈"
        case .rabbit:     return "🐇"
        case .bird:       return "🦜"
        case .fish:       return "🐠"
        case .hamster:    return "🐹"
        case .horse:      return "🐴"
        case .snake:      return "🐍"
        case .lizard:     return "🦎"
        case .turtle:     return "🐢"
        case .frog:       return "🐸"
        case .guinea_pig: return "🦫"
        case .ferret:     return "🦫"
        case .hedgehog:   return "🦔"
        case .chinchilla: return "🐭"
        case .goat:       return "🐐"
        case .sheep:      return "🐑"
        case .pig:        return "🐷"
        case .chicken:    return "🐔"
        }
    }

    /// SF Symbol used as a stand-in for the pet type.
    var sfSymbol: String {
        switch self {
        case .dog:        return "pawprint.fill"
        case .cat:        return "pawprint"
        case .rabbit:     return "hare.fill"
        case .bird:       return "bird.fill"
        case .fish:       return "fish.fill"
        case .hamster:    return "hare.fill"
        case .horse:      return "horse.fill"
        case .snake:      return "tortoise.fill"
        case .lizard:     return "tortoise"
        case .turtle:     return "tortoise.fill"
        case .frog:       return "frog.fill"
        case .guinea_pig: return "hare.fill"
        case .ferret:     return "pawprint"
        case .hedgehog:   return "pawprint"
        case .chinchilla: return "hare"
        case .goat:       return "pawprint"
        case .sheep:      return "pawprint"
        case .pig:        return "pawprint"
        case .chicken:    return "bird"
        }
    }

    /// Partial list of breeds per species.
    var breeds: [String] {
        switch self {
        case .dog:
            return ["Mixed", "Indian Pariah", "Labrador", "Golden Retriever", "Beagle",
                    "Pug", "Shih Tzu", "German Shepherd", "Pomeranian", "Rottweiler",
                    "Cocker Spaniel", "Doberman", "Dachshund", "Siberian Husky",
                    "French Bulldog", "Bulldog", "Border Collie", "Dalmatian"]
        case .cat:
            return ["Mixed", "Indian Billi", "Persian", "Siamese", "Bombay",
                    "Maine Coon", "Ragdoll", "British Shorthair", "Bengal",
                    "Scottish Fold", "Sphynx", "Russian Blue", "Abyssinian"]
        case .rabbit:
            return ["Mixed", "Holland Lop", "Netherland Dwarf", "Mini Lop", "Flemish Giant",
                    "Lionhead", "Rex", "Dutch", "Angora"]
        case .bird:
            return ["Mixed", "Budgerigar", "Cockatiel", "Indian Ringneck",
                    "Lovebird", "Canary", "Finch", "Parakeet", "Macaw", "Cockatoo"]
        case .fish:
            return ["Mixed", "Goldfish", "Betta", "Guppy", "Tetra", "Angelfish",
                    "Molly", "Platy", "Cichlid", "Discus", "Koi"]
        case .hamster:
            return ["Mixed", "Syrian", "Roborovski", "Winter White", "Campbell's Dwarf", "Chinese"]
        case .horse:
            return ["Mixed", "Arabian", "Thoroughbred", "Quarter Horse", "Clydesdale",
                    "Shire", "Mustang", "Appaloosa", "Fjord", "Hanoverian"]
        case .snake:
            return ["Mixed", "Ball Python", "Corn Snake", "King Snake", "Boa Constrictor",
                    "Reticulated Python", "Garter Snake", "Hognose"]
        case .lizard:
            return ["Mixed", "Bearded Dragon", "Leopard Gecko", "Crested Gecko", "Blue Tongue Skink",
                    "Iguana", "Chameleon", "Uromastyx", "Tegu"]
        case .turtle:
            return ["Mixed", "Red-Eared Slider", "Box Turtle", "Russian Tortoise",
                    "Greek Tortoise", "Sulcata", "Pond Turtle"]
        case .frog:
            return ["Mixed", "White's Tree Frog", "Pacman Frog", "Dart Frog",
                    "Fire-Bellied Toad", "Axolotl"]
        case .guinea_pig:
            return ["Mixed", "American", "Abyssinian", "Peruvian", "Silkie", "Teddy", "Rex"]
        case .ferret:
            return ["Mixed", "Angora", "SILVER", "Blaze", "Panda", "Chocolate"]
        case .hedgehog:
            return ["Mixed", "African Pygmy", " Algerian", "White-Bellied", "Four-Toed"]
        case .chinchilla:
            return ["Mixed", "Standard Grey", "Black Velvet", "White", "Beige", "Sapphire", "Violet"]
        case .goat:
            return ["Mixed", "Nigerian Dwarf", "Pygmy", "Alpine", "Boer", "Saanen", "Kiko"]
        case .sheep:
            return ["Mixed", "Merino", "Suffolk", "Dorper", "Romney", "Jacob", "Baa"]
        case .pig:
            return ["Mixed", "Mini Pig", "Pot-Bellied", "Vietnames Pot-Bellied", "Kunekune", "Hampshire"]
        case .chicken:
            return ["Mixed", "Rhode Island Red", "Leghorn", "Plymouth Rock", "Wyandotte",
                    "Silkie", "Orpington", "Easter Egger", "Bantam"]
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
