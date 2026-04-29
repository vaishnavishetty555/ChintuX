import SwiftUI

// MARK: - Welcome

struct WelcomeScreen: View {
    var onContinue: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: Spacing.m) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(PawlyColors.forest)
                Text("Pawly")
                    .font(PawlyFont.displayLarge)
                    .foregroundStyle(PawlyColors.ink)
                Text("A calmer home for the moments you share with your pet.")
                    .font(PawlyFont.bodyLarge)
                    .foregroundStyle(PawlyColors.slate)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            Spacer()
            Button("Get Started", action: onContinue)
                .buttonStyle(.pawlyPrimary)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - Basics (name / species / breed / DOB / photo)

struct BasicsScreen: View {
    @ObservedObject var draft: OnboardingDraft
    var onBack: () -> Void
    var onNext: () -> Void

    private var canContinue: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        OnboardingScaffold(
            title: "Let's meet your pet",
            subtitle: "A few warm details is all we need.",
            onBack: onBack, onNext: onNext, nextEnabled: canContinue
        ) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                PhotoUploadTile(data: $draft.photoData)

                PawlyTextField(label: "Pet's name", text: $draft.name, placeholder: "Mochi")
                    .textInputAutocapitalization(.words)

                speciesPicker

                BreedPicker(species: draft.species, breed: $draft.breed)

                Toggle(isOn: $draft.hasDateOfBirth) {
                    Text("I know their date of birth").font(PawlyFont.bodyMedium)
                }
                .tint(PawlyColors.forest)

                if draft.hasDateOfBirth {
                    DatePicker("Date of birth",
                               selection: $draft.dateOfBirth,
                               in: ...Date(),
                               displayedComponents: .date)
                        .tint(PawlyColors.forest)
                }
            }
        }
    }

    private var speciesPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Species").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
            HStack(spacing: Spacing.xs) {
                ForEach(Species.allCases) { s in
                    SpeciesChip(species: s, selected: draft.species == s) {
                        draft.species = s
                        draft.breed = s.breeds.first ?? ""
                    }
                }
            }
        }
    }
}

private struct SpeciesChip: View {
    let species: Species
    let selected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: species.sfSymbol)
                    .font(.system(size: 20, weight: .medium))
                Text(species.displayName).font(PawlyFont.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundStyle(selected ? Color.white : PawlyColors.ink)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(selected ? PawlyColors.forest : PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(PawlyColors.sand, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct BreedPicker: View {
    let species: Species
    @Binding var breed: String
    @State private var search: String = ""

    var filtered: [String] {
        if search.isEmpty { return species.breeds }
        return species.breeds.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Breed").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
            Menu {
                TextField("Search", text: $search).textInputAutocapitalization(.words)
                Divider()
                ForEach(filtered, id: \.self) { name in
                    Button(name) { breed = name }
                }
            } label: {
                HStack {
                    Text(breed.isEmpty ? "Select breed" : breed)
                        .font(PawlyFont.bodyLarge)
                        .foregroundStyle(breed.isEmpty ? PawlyColors.slate : PawlyColors.ink)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(PawlyColors.slate)
                }
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, Spacing.s)
                .frame(minHeight: Spacing.tapTargetMin)
                .background(
                    RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                        .fill(PawlyColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                        .stroke(PawlyColors.sand, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Profile (weight, sex, neuter, allergies)

struct ProfileScreen: View {
    @ObservedObject var draft: OnboardingDraft
    var onBack: () -> Void
    var onNext: () -> Void

    var body: some View {
        OnboardingScaffold(
            title: "Tell us about \(draft.name.isEmpty ? "them" : draft.name)",
            subtitle: "This makes reminders and AI Doctor more useful.",
            onBack: onBack, onNext: onNext, nextEnabled: true
        ) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                PawlyTextField(label: "Weight (kg)", text: $draft.weightKg,
                               placeholder: "4.0", keyboard: .decimalPad,
                               autocapitalization: .never)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Sex").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                    Picker("Sex", selection: $draft.sex) {
                        ForEach(PetSex.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle(isOn: $draft.neutered) {
                    Text("Neutered / Spayed").font(PawlyFont.bodyMedium)
                }
                .tint(PawlyColors.forest)

                PawlyTextField(label: "Allergies",
                               text: $draft.allergies,
                               placeholder: "e.g. fish, chicken")

                PawlyTextField(label: "Ongoing conditions",
                               text: $draft.conditions,
                               placeholder: "e.g. arthritis")
            }
        }
    }
}

// MARK: - Reminders toggle

struct RemindersScreen: View {
    @ObservedObject var draft: OnboardingDraft
    var onBack: () -> Void
    var onNext: () -> Void

    var body: some View {
        OnboardingScaffold(
            title: "A gentle nudge or two",
            subtitle: "Flip on what helps. You can change these later.",
            onBack: onBack, onNext: onNext, nextEnabled: true
        ) {
            VStack(spacing: Spacing.s) {
                ForEach($draft.firstReminders) { $t in
                    PawlyCard {
                        HStack(spacing: Spacing.m) {
                            Image(systemName: t.type.sfSymbol)
                                .font(.system(size: 18))
                                .foregroundStyle(PawlyColors.forest)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(PawlyColors.cream))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.title).font(PawlyFont.bodyLarge).foregroundStyle(PawlyColors.ink)
                                Text(t.recurrence.displayDescription)
                                    .font(PawlyFont.caption)
                                    .foregroundStyle(PawlyColors.slate)
                            }
                            Spacer()
                            Toggle("", isOn: $t.enabled).labelsHidden().tint(PawlyColors.forest)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Invite (optional, cosmetic)

struct InviteScreen: View {
    @ObservedObject var draft: OnboardingDraft
    var onBack: () -> Void
    var onFinish: () -> Void

    var body: some View {
        OnboardingScaffold(
            title: "Share the care (optional)",
            subtitle: "Invite a partner later from Settings. For now, let's get you home.",
            onBack: onBack,
            onNext: onFinish,
            nextTitle: "Finish",
            nextEnabled: true
        ) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                PawlyCard {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Your invite code").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        Text("PAWLY-" + String(Int.random(in: 1000...9999)))
                            .font(PawlyFont.displayMedium)
                            .foregroundStyle(PawlyColors.forest)
                        Text("Partner accounts are coming soon — this code is a placeholder.")
                            .font(PawlyFont.caption)
                            .foregroundStyle(PawlyColors.slate)
                    }
                }
            }
        }
    }
}

// MARK: - Shared scaffold

struct OnboardingScaffold<Content: View>: View {
    let title: String
    var subtitle: String = ""
    var onBack: () -> Void
    var onNext: () -> Void
    var nextTitle: String = "Continue"
    var nextEnabled: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(title)
                            .font(PawlyFont.displayMedium)
                            .foregroundStyle(PawlyColors.ink)
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(PawlyFont.bodyLarge)
                                .foregroundStyle(PawlyColors.slate)
                        }
                    }
                    content()
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.xxl)
            }
            HStack(spacing: Spacing.s) {
                Button("Back", action: onBack)
                    .buttonStyle(.pawlySecondary)
                Button(nextTitle, action: onNext)
                    .buttonStyle(.pawlyPrimary)
                    .disabled(!nextEnabled)
                    .opacity(nextEnabled ? 1 : 0.5)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.l)
        }
    }
}

struct PhotoUploadTile: View {
    @Binding var data: Data?

    var body: some View {
        PhotoPickerButton(data: $data) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(PawlyColors.surface)
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(
                        PawlyColors.sand,
                        style: StrokeStyle(lineWidth: 1.5, dash: data == nil ? [6, 6] : [])
                    )
                Group {
                    if let data, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 22))
                            Text("Add a photo").font(PawlyFont.caption)
                        }
                        .foregroundStyle(PawlyColors.slate)
                    }
                }
            }
            .frame(height: 140)
        }
        .buttonStyle(.plain)
    }
}
