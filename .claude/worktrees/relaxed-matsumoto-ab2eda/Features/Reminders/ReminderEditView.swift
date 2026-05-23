import SwiftUI
import SwiftData

/// PRD §6.3 — Reminder create/edit screen.
struct ReminderEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Pet this reminder belongs to (required on create).
    let pet: Pet
    /// Existing reminder to edit, or nil for create.
    let existing: Reminder?

    @State private var title: String = ""
    @State private var type: ReminderType = .medication
    @State private var dosage: String = ""
    @State private var recurrence: Recurrence = .once
    @State private var firstDueAt: Date = Date()
    @State private var notes: String = ""
    @State private var prescriptionPhotoData: Data?
    @State private var useQuietHours: Bool = false
    @State private var quietStart: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now)!
    @State private var quietEnd:   Date = Calendar.current.date(bySettingHour: 8,  minute: 0, second: 0, of: .now)!

    init(pet: Pet, existing: Reminder? = nil) {
        self.pet = pet
        self.existing = existing
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    typePicker

                    PawlyTextField(label: "Title", text: $title, placeholder: "Deworming tablet")
                        .textInputAutocapitalization(.sentences)

                    if type == .medication {
                        PawlyTextField(label: "Dosage", text: $dosage, placeholder: "1 tablet")
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("First occurrence").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        DatePicker("First occurrence", selection: $firstDueAt).labelsHidden()
                            .tint(PawlyColors.forest)
                    }

                    RecurrencePicker(recurrence: $recurrence)

                    PawlyCard {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Toggle("Quiet hours", isOn: $useQuietHours).tint(PawlyColors.forest)
                            if useQuietHours {
                                HStack {
                                    DatePicker("From", selection: $quietStart, displayedComponents: .hourAndMinute)
                                    DatePicker("To",   selection: $quietEnd,   displayedComponents: .hourAndMinute)
                                }
                                .font(PawlyFont.bodyMedium)
                            }
                        }
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

                    PhotoPickerButton(data: $prescriptionPhotoData) {
                        HStack {
                            Image(systemName: "paperclip")
                            Text(prescriptionPhotoData == nil ? "Attach prescription photo" : "Change prescription photo")
                        }
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.forest)
                        .padding(.vertical, Spacing.s)
                    }

                    if let existing {
                        Button("Delete reminder", role: .destructive) {
                            modelContext.delete(existing)
                            try? modelContext.save()
                            dismiss()
                        }
                        .buttonStyle(.pawlyDestructive)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.l)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationTitle(existing == nil ? "New reminder" : "Edit reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
        type = existing.type
        dosage = existing.dosage ?? ""
        recurrence = existing.recurrence
        firstDueAt = existing.firstDueAt
        notes = existing.notes
        prescriptionPhotoData = existing.prescriptionPhotoData
        useQuietHours = existing.quietStartHour >= 0
        if useQuietHours {
            let cal = Calendar.current
            quietStart = cal.date(bySettingHour: existing.quietStartHour, minute: 0, second: 0, of: .now) ?? quietStart
            quietEnd   = cal.date(bySettingHour: existing.quietEndHour,   minute: 0, second: 0, of: .now) ?? quietEnd
        }
    }

    private func save() {
        let cal = Calendar.current
        let qs = useQuietHours ? cal.component(.hour, from: quietStart) : -1
        let qe = useQuietHours ? cal.component(.hour, from: quietEnd)   : -1

        if let existing {
            existing.title = title.trimmingCharacters(in: .whitespaces)
            existing.typeRaw = type.rawValue
            existing.dosage = dosage.isEmpty ? nil : dosage
            existing.recurrenceRaw = recurrence.rawString
            existing.firstDueAt = firstDueAt
            existing.notes = notes
            existing.prescriptionPhotoData = prescriptionPhotoData
            existing.quietStartHour = qs
            existing.quietEndHour = qe
            // Re-expand future instances
            existing.instances.filter { $0.scheduledAt > .now && $0.status == .upcoming }
                .forEach { modelContext.delete($0) }
            expandInstances(for: existing)
        } else {
            let new = Reminder(
                pet: pet,
                title: title.trimmingCharacters(in: .whitespaces),
                type: type,
                dosage: dosage.isEmpty ? nil : dosage,
                recurrence: recurrence,
                firstDueAt: firstDueAt,
                notes: notes,
                prescriptionPhotoData: prescriptionPhotoData,
                quietStartHour: qs,
                quietEndHour: qe
            )
            modelContext.insert(new)
            expandInstances(for: new)
        }
        try? modelContext.save()
        dismiss()
    }

    private func expandInstances(for reminder: Reminder) {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 120, to: .now) ?? .now
        let start = max(reminder.firstDueAt, Date().addingTimeInterval(-60))
        let dates = RecurrenceEngine.occurrences(
            recurrence: reminder.recurrence,
            firstDueAt: reminder.firstDueAt,
            in: start..<end
        )
        for d in dates {
            let inst = ReminderInstance(reminder: reminder, scheduledAt: d)
            modelContext.insert(inst)
            NotificationService.schedule(
                reminderInstanceID: inst.id,
                reminderID: reminder.id,
                petName: pet.name,
                title: reminder.title,
                body: "\(pet.name) has a scheduled \(reminder.type.displayName.lowercased()).",
                fireDate: d
            )
        }
    }
}
