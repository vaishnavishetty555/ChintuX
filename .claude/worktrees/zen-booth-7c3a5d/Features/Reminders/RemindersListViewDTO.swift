import SwiftUI

/// List of all reminders for a pet with next-occurrence info.
struct RemindersListViewDTO: View {
    let pet: PetDTO
    @EnvironmentObject var dataStore: DataStore
    @State private var showingNew = false
    @State private var editingReminder: ReminderDTO?

    private var sortedReminders: [ReminderDTO] {
        dataStore.reminders(forPetId: pet.id)
            .filter { $0.isActive }
            .sorted { $0.firstDueAt < $1.firstDueAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.s) {
                if sortedReminders.isEmpty {
                    PawlyCard {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            Text("No reminders yet").font(PawlyFont.headingMedium).foregroundStyle(PawlyColors.ink)
                            Text("Add a reminder to nudge you about meds, vaccines, or grooming.")
                                .font(PawlyFont.bodyMedium)
                                .foregroundStyle(PawlyColors.slate)
                        }
                    }
                } else {
                    ForEach(sortedReminders) { r in
                        Button { editingReminder = r } label: {
                            ReminderRowDTO(reminder: r, dataStore: dataStore)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.m)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle("\(pet.name)'s reminders")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNew = true } label: {
                    Image(systemName: "plus")
                }
                .tint(PawlyColors.forest)
            }
        }
        .sheet(isPresented: $showingNew) {
            ReminderEditViewDTO(pet: pet, existing: nil)
        }
        .sheet(item: $editingReminder) { r in
            ReminderEditViewDTO(pet: pet, existing: r)
        }
    }
}

private struct ReminderRowDTO: View {
    let reminder: ReminderDTO
    let dataStore: DataStore

    private var next: ReminderInstanceDTO? {
        dataStore.reminderInstances(forReminderId: reminder.id)
            .filter { $0.statusRaw == "upcoming" && $0.scheduledAt >= .now }
            .min(by: { $0.scheduledAt < $1.scheduledAt })
    }

    var body: some View {
        PawlyCard {
            HStack(spacing: Spacing.m) {
                if let type = ReminderType(rawValue: reminder.typeRaw) {
                    Image(systemName: type.sfSymbol)
                        .foregroundStyle(PawlyColors.forest)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(PawlyColors.cream))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title).font(PawlyFont.bodyLarge).foregroundStyle(PawlyColors.ink)
                    if let recurrence = Recurrence(rawString: reminder.recurrenceRaw) {
                        Text(recurrence.displayDescription)
                            .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                    }
                    if let next {
                        Text("Next: \(next.scheduledAt, format: .dateTime.month(.abbreviated).day().hour().minute())")
                            .font(PawlyFont.captionSmall).foregroundStyle(PawlyColors.sage)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(PawlyColors.slate)
            }
        }
    }
}

// MARK: - Reminder Edit View DTO

struct ReminderEditViewDTO: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    let pet: PetDTO
    let existing: ReminderDTO?

    @State private var title: String = ""
    @State private var type: ReminderType
    @State private var dosage: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""

    init(pet: PetDTO, existing: ReminderDTO? = nil, defaultType: ReminderType = .medication) {
        self.pet = pet
        self.existing = existing
        _type = State(initialValue: existing.flatMap { ReminderType(rawValue: $0.typeRaw) } ?? defaultType)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    typePicker

                    PawlyTextField(label: "Title", text: $title, placeholder: type.titlePlaceholder)
                        .textInputAutocapitalization(.sentences)

                    if type == .medication {
                        PawlyTextField(label: "Dosage", text: $dosage, placeholder: "1 tablet")
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Date").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .tint(PawlyColors.forest)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Notes").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(Spacing.s)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.input)
                                    .fill(PawlyColors.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.input)
                                    .stroke(PawlyColors.sand, lineWidth: 1)
                            )
                    }

                    if let existing {
                        Button("Delete reminder", role: .destructive) {
                            Task {
                                await dataStore.deleteReminder(id: existing.id)
                                dismiss()
                            }
                        }
                        .buttonStyle(.pawlyDestructive)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.l)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationTitle(existing == nil ? (type == .vetCheckup ? "Schedule vet visit" : "New reminder") : "Edit reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { 
                        Task {
                            await save()
                        }
                    }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .tint(PawlyColors.forest)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Type").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
            Picker("Type", selection: $type) {
                ForEach(ReminderType.allCases) { t in
                    Label(t.displayName, systemImage: t.sfSymbol).tag(t)
                }
            }
            .pickerStyle(.menu)
            .tint(PawlyColors.forest)
        }
    }

    private func loadExisting() {
        guard let existing else { return }
        title = existing.title
        type = ReminderType(rawValue: existing.typeRaw) ?? .medication
        dosage = existing.dosage ?? ""
        date = existing.firstDueAt
        notes = existing.notes
    }

    private func save() async {
        if let existing {
            let updated = ReminderDTO(
                id: existing.id,
                petId: pet.id,
                title: title.trimmingCharacters(in: .whitespaces),
                typeRaw: type.rawValue,
                dosage: dosage.isEmpty ? nil : dosage,
                recurrenceRaw: Recurrence.once.rawString,
                firstDueAt: date,
                notes: notes,
                quietStartHour: -1,
                quietEndHour: -1,
                createdAt: existing.createdAt,
                isActive: existing.isActive
            )
            await dataStore.updateReminder(updated)
        } else {
            await dataStore.createReminder(
                forPetId: pet.id,
                title: title.trimmingCharacters(in: .whitespaces),
                type: type,
                recurrence: .once,
                firstDueAt: date,
                dosage: dosage.isEmpty ? nil : dosage,
                notes: notes
            )
        }
        dismiss()
    }
}
