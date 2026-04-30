import SwiftUI

/// PRD §7 Flow 1 — from open to first reminder logged in under 60 seconds, ≤4 taps.
struct QuickLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    @State private var selectedKind: LogKind = .meal
    @State private var detail: String = ""
    @State private var numericValue: String = ""

    private var activePet: PetDTO? {
        dataStore.pets.first(where: { $0.id == petContext.activePetID && $0.statusRaw == "active" }) 
            ?? dataStore.pets.first { $0.statusRaw == "active" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    if dataStore.pets.filter({ $0.statusRaw == "active" }).count > 1 {
                        petRow
                    }

                    // Kind selector
                    HStack(spacing: Spacing.xs) {
                        ForEach(LogKind.allCases) { k in
                            KindChip(kind: k, selected: selectedKind == k) {
                                Haptics.light()
                                selectedKind = k
                            }
                        }
                    }

                    // Dynamic form per kind
                    switch selectedKind {
                    case .meal:
                        quickPicker(options: ["Dry food", "Wet food", "Home-cooked", "Treats"])
                        PawlyTextField(label: "Notes", text: $detail, placeholder: "Half pouch")
                    case .medication:
                        quickPicker(options: lastMedNames)
                        PawlyTextField(label: "Dosage / notes", text: $detail, placeholder: "1 tablet")
                    case .walk:
                        PawlyTextField(label: "Duration / notes", text: $detail, placeholder: "15 min balcony")
                    case .weight:
                        PawlyTextField(label: "Weight (kg)", text: $numericValue, placeholder: "4.2", keyboard: .decimalPad, autocapitalization: .never)
                    case .hygiene:
                        quickPicker(options: ["Brushing", "Nail trim", "Ear clean", "Bath"])
                    }

                    Button {
                        Task {
                            await save()
                        }
                    } label: {
                        Label("Log for \(activePet?.name ?? "pet")", systemImage: "checkmark")
                    }
                    .buttonStyle(.pawlyPrimary)
                    .disabled(activePet == nil)

                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationTitle("Quick log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var petRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(dataStore.pets.filter { $0.statusRaw == "active" }) { pet in
                    Button {
                        petContext.setActive(pet)
                        Haptics.light()
                    } label: {
                        VStack(spacing: 4) {
                            PetAvatarDTO(pet: pet, size: 44)
                            Text(pet.name).font(PawlyFont.caption).foregroundStyle(PawlyColors.ink)
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.card)
                                .fill(pet.id == activePet?.id ? Color(hex: pet.accentHex).opacity(0.15) : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var lastMedNames: [String] {
        guard let petId = activePet?.id else { return ["Vitamin drops", "Deworming tablet", "Tick & flea drops"] }
        let recent = dataStore.logEntries(forPetId: petId)
            .filter { $0.kindRaw == "medication" }
            .sorted(by: { $0.at > $1.at })
            .prefix(5)
            .map(\.detail)
            .filter { !$0.isEmpty }
        let defaults = ["Vitamin drops", "Deworming tablet", "Tick & flea drops"]
        let combined = Array(Set(recent + defaults))
        return combined.sorted()
    }

    @ViewBuilder
    private func quickPicker(options: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.self) { opt in
                    Button {
                        detail = opt
                        Haptics.light()
                    } label: {
                        Text(opt)
                            .font(PawlyFont.caption)
                            .padding(.horizontal, Spacing.s)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(
                                detail == opt ? PawlyColors.forest : PawlyColors.surface
                            ))
                            .foregroundStyle(detail == opt ? Color.white : PawlyColors.ink)
                            .overlay(Capsule().stroke(PawlyColors.sand, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func save() async {
        guard let pet = activePet else { return }
        let num = Double(numericValue)
        
        await dataStore.createLogEntry(
            forPetId: pet.id,
            kind: selectedKind,
            detail: detail,
            numericValue: num
        )
        
        Haptics.success()
        dismiss()
    }
}

private struct KindChip: View {
    let kind: LogKind
    let selected: Bool
    var onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: kind.sfSymbol)
                    .font(.system(size: 18, weight: selected ? .semibold : .regular))
                Text(kind.displayName).font(PawlyFont.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundStyle(selected ? Color.white : PawlyColors.ink)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(selected ? PawlyColors.forest : PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card).stroke(PawlyColors.sand, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
