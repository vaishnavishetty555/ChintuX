import SwiftUI

/// Quick Log sheet — PRD §7 Flow 1. ≤4 taps from open to first reminder logged.
/// Modern bottom-sheet design with clean type selector and contextual forms.
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
                VStack(alignment: .leading, spacing: Spacing.l) {
                    // Pet selector (if multiple pets)
                    if dataStore.pets.filter({ $0.statusRaw == "active" }).count > 1 {
                        petRow
                    }

                    // Kind selector — large tappable chips
                    HStack(spacing: Spacing.xs) {
                        ForEach(LogKind.allCases) { k in
                            KindChip(kind: k, selected: selectedKind == k) {
                                Haptics.light()
                                selectedKind = k
                                detail = ""
                            }
                        }
                    }

                    // Dynamic form
                    switch selectedKind {
                    case .meal:
                        quickPicker(options: ["Dry food", "Wet food", "Home-cooked", "Treats"])
                        PawlyTextField(label: "Notes", text: $detail, placeholder: "Half pouch")
                    case .medication:
                        quickPicker(options: lastMedNames)
                        PawlyTextField(label: "Dosage / notes", text: $detail, placeholder: "1 tablet")
                    case .walk:
                        PawlyTextField(label: "Duration / notes", text: $detail, placeholder: "15 min walk")
                    case .weight:
                        PawlyTextField(
                            label: "Weight (kg)",
                            text: $numericValue,
                            placeholder: "4.2",
                            keyboard: .decimalPad,
                            autocapitalization: .never
                        )
                    case .hygiene:
                        quickPicker(options: ["Brushing", "Nail trim", "Ear clean", "Bath"])
                    }

                    // Save button
                    Button {
                        Task { await save() }
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
                        .foregroundStyle(PawlyColors.slate)
                }
            }
        }
    }

    // MARK: - Pet Row

    private var petRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(dataStore.pets.filter { $0.statusRaw == "active" }) { pet in
                    Button {
                        petContext.setActive(pet)
                        Haptics.light()
                    } label: {
                        VStack(spacing: 5) {
                            PetAvatarDTO(pet: pet, size: 44)
                            Text(pet.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(PawlyColors.ink)
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.small)
                                .fill(pet.id == activePet?.id
                                      ? Color(hex: pet.accentHex).opacity(0.15)
                                      : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.small)
                                .stroke(pet.id == activePet?.id
                                        ? Color(hex: pet.accentHex)
                                        : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Quick Picker

    private var lastMedNames: [String] {
        guard let petId = activePet?.id else {
            return ["Vitamin drops", "Deworming tablet", "Tick & flea drops"]
        }
        let recent = dataStore.logEntries(forPetId: petId)
            .filter { $0.kindRaw == "medication" }
            .sorted(by: { $0.at > $1.at })
            .prefix(5)
            .map(\.detail)
            .filter { !$0.isEmpty }
        let defaults = ["Vitamin drops", "Deworming tablet", "Tick & flea drops"]
        return Array(Set(recent + defaults)).sorted()
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
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(detail == opt ? PawlyColors.forest : PawlyColors.surface)
                            )
                            .overlay(
                                Capsule().stroke(
                                    detail == opt ? PawlyColors.forest : PawlyColors.sand.opacity(0.5),
                                    lineWidth: 0.75
                                )
                            )
                            .foregroundStyle(detail == opt ? .white : PawlyColors.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Save

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

// MARK: - Kind Chip

private struct KindChip: View {
    let kind: LogKind
    let selected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Image(systemName: kind.sfSymbol)
                    .font(.system(size: 18, weight: selected ? .semibold : .regular))
                Text(kind.displayName)
                    .font(.system(size: 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 62)
            .foregroundStyle(selected ? .white : PawlyColors.ink)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(selected ? PawlyColors.forest : PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(selected ? PawlyColors.forest : PawlyColors.sand.opacity(0.4), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }
}