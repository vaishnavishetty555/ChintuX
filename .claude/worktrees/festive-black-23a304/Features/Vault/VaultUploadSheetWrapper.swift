import SwiftUI
import SwiftData

/// Bridges VaultHomeView (PetDTO-based) to DocumentUploadSheet (SwiftData Pet-based).
/// Finds or creates a matching SwiftData Pet when uploading documents.
struct VaultUploadSheetWrapper: View {
    let activePet: PetDTO?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let pet = resolveOrCreateSwiftDataPet()
        if let pet {
            DocumentUploadSheet(pet: pet)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(PawlyColors.inkSoft.opacity(0.4))
                Text("No pet selected")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                Text("Please select a pet from the home screen first.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .multilineTextAlignment(.center)
                Button("Close") { dismiss() }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(PawlyColors.peachAccent)
                    .clipShape(Capsule())
            }
            .padding(40)
            .presentationDetents([.medium])
        }
    }

    /// Finds an existing SwiftData Pet by matching UUID, or creates one if it doesn't exist.
    private func resolveOrCreateSwiftDataPet() -> Pet? {
        guard let dto = activePet else { return nil }

        // Try to find existing SwiftData Pet by UUID
        let descriptor = FetchDescriptor<Pet>(
            predicate: #Predicate { $0.id == dto.id }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        // No SwiftData Pet found — create one from the DTO so documents can be associated
        let species = Species(rawValue: dto.speciesRaw) ?? .cat
        let sex = PetSex(rawValue: dto.sexRaw) ?? .unknown
        let status = PetStatus(rawValue: dto.statusRaw) ?? .active

        let newPet = Pet(
            id: dto.id,
            name: dto.name,
            species: species,
            breed: dto.breed,
            dateOfBirth: dto.dateOfBirth,
            weightKg: dto.weightKg,
            sex: sex,
            neutered: dto.neutered,
            allergiesText: dto.allergiesText,
            ongoingConditionsText: dto.ongoingConditionsText,
            accentHex: dto.accentHex,
            photoData: nil,
            status: status,
            vetName: dto.vetName,
            vetPhone: dto.vetPhone,
            createdAt: dto.createdAt
        )

        modelContext.insert(newPet)
        try? modelContext.save()
        return newPet
    }
}