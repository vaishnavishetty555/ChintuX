import SwiftUI
import SwiftData

/// Bridges VaultHomeView (PetDTO-based) to DocumentUploadSheet (SwiftData Pet-based).
/// Resolves the SwiftData Pet in a task (not in body) to avoid side effects during rendering.
struct VaultUploadSheetWrapper: View {
    let activePet: PetDTO?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var resolvedPet: Pet? = nil
    @State private var resolved = false

    var body: some View {
        Group {
            if !resolved {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(PawlyColors.cream.ignoresSafeArea())
            } else if let pet = resolvedPet {
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
        .task {
            resolvedPet = resolveOrCreateSwiftDataPet()
            resolved = true
        }
    }

    /// Finds an existing SwiftData Pet by matching UUID, or creates one from the DTO.
    private func resolveOrCreateSwiftDataPet() -> Pet? {
        guard let dto = activePet else { return nil }

        let dtoId = dto.id
        let descriptor = FetchDescriptor<Pet>(
            predicate: #Predicate { $0.id == dtoId }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

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
