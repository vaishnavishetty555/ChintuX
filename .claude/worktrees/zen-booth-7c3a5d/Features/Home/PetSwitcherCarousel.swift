import SwiftUI

/// Compact pet switcher in the top-right of Home / Calendar.
/// Single pet → just an avatar. Multi-pet → tap to expand and pick.
struct PetSwitcherCarousel: View {
    let pets: [PetDTO]
    @EnvironmentObject var petContext: PetContextStore

    @State private var expanded = false

    var activePet: PetDTO? {
        pets.first(where: { $0.id == petContext.activePetID }) ?? pets.first
    }

    var body: some View {
        if pets.count <= 1 {
            avatarView(for: activePet, selected: true, size: 40)
        } else {
            Menu {
                ForEach(pets) { pet in
                    Button {
                        Haptics.light()
                        petContext.setActive(pet)
                    } label: {
                        Label(pet.name, systemImage: pet.id == activePet?.id ? "checkmark" : "")
                    }
                }
            } label: {
                HStack(spacing: -10) {
                    if let other = pets.first(where: { $0.id != activePet?.id }) {
                        avatarView(for: other, selected: false, size: 32)
                            .opacity(0.85)
                    }
                    avatarView(for: activePet, selected: true, size: 40)
                        .zIndex(2)
                }
            }
            .accessibilityLabel("Switch pet, currently \(activePet?.name ?? "none")")
        }
    }

    @ViewBuilder
    private func avatarView(for pet: PetDTO?, selected: Bool, size: CGFloat) -> some View {
        ZStack {
            if let photoURL = pet?.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(hex: pet?.accentHex ?? "#1F4E40")
                }
            } else {
                Color(hex: pet?.accentHex ?? "#1F4E40")
                    .overlay(
                        Image(systemName: Species(rawValue: pet?.speciesRaw ?? "dog")?.sfSymbol ?? "pawprint.fill")
                            .foregroundStyle(Color.white.opacity(0.92))
                            .font(.system(size: size * 0.42, weight: .semibold))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Color.white, lineWidth: 1.5)
        )
        .shadow(color: PawlyColors.shadowWarm, radius: 4, x: 0, y: 2)
    }
}
