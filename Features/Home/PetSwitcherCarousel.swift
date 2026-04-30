import SwiftUI

/// PRD §5.2 — The pet switcher: avatar(s) in top-left. Single-pet households
/// render only the active avatar; multi-pet renders a horizontal carousel that
/// opens on tap.
struct PetSwitcherCarousel: View {
    let pets: [PetDTO]
    @EnvironmentObject var petContext: PetContextStore

    @State private var expanded = false

    var activePet: PetDTO? {
        pets.first(where: { $0.id == petContext.activePetID }) ?? pets.first
    }

    var body: some View {
        if pets.count <= 1 {
            avatarView(for: activePet, selected: true)
                .frame(width: 44, height: 44)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(Motion.transition) { expanded.toggle() }
                } label: {
                    HStack(spacing: -8) {
                        avatarView(for: activePet, selected: true)
                            .frame(width: 44, height: 44)
                            .zIndex(2)
                        if let other = pets.first(where: { $0.id != activePet?.id }) {
                            avatarView(for: other, selected: false)
                                .frame(width: 36, height: 36)
                                .opacity(0.8)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Switch pet, currently \(activePet?.name ?? "none")")

                if expanded {
                    HStack(spacing: Spacing.s) {
                        ForEach(pets) { pet in
                            Button {
                                Haptics.medium()
                                petContext.setActive(pet)
                                withAnimation(Motion.transition) { expanded = false }
                            } label: {
                                avatarView(for: pet, selected: pet.id == activePet?.id)
                                    .frame(width: 56, height: 56)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .fill(PawlyColors.surface)
                            .shadow(color: PawlyColors.ink.opacity(0.08), radius: 8, y: 2)
                    )
                    .padding(.top, Spacing.xs)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
        }
    }

    @ViewBuilder
    private func avatarView(for pet: PetDTO?, selected: Bool) -> some View {
        ZStack {
            if let photoURL = pet?.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(hex: pet?.accentHex ?? "#2D5F4E")
                }
            } else {
                Color(hex: pet?.accentHex ?? "#2D5F4E")
                    .overlay(
                        Image(systemName: Species(rawValue: pet?.speciesRaw ?? "dog")?.sfSymbol ?? "pawprint.fill")
                            .foregroundStyle(Color.white.opacity(0.9))
                            .font(.system(size: 20, weight: .semibold))
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.avatar, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.avatar, style: .continuous)
                .stroke(selected ? Color(hex: pet?.accentHex ?? "#2D5F4E") : Color.clear,
                        lineWidth: 2.5)
        )
    }
}
