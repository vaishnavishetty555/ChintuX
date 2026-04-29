import SwiftUI
import SwiftData

/// List of all reminders for a pet with next-occurrence info.
struct RemindersListView: View {
    let pet: Pet

    @Environment(\.modelContext) private var modelContext
    @State private var presenting: Reminder?
    @State private var showingNew = false

    private var sortedReminders: [Reminder] {
        pet.reminders
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
                        Button { presenting = r } label: {
                            ReminderRow(reminder: r)
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
            ReminderEditView(pet: pet, existing: nil)
        }
        .sheet(item: $presenting) { r in
            ReminderEditView(pet: pet, existing: r)
        }
    }
}

private struct ReminderRow: View {
    let reminder: Reminder

    private var next: ReminderInstance? {
        reminder.instances
            .filter { $0.status == .upcoming && $0.scheduledAt >= .now }
            .min(by: { $0.scheduledAt < $1.scheduledAt })
    }

    var body: some View {
        PawlyCard {
            HStack(spacing: Spacing.m) {
                Image(systemName: reminder.type.sfSymbol)
                    .foregroundStyle(PawlyColors.forest)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(PawlyColors.cream))
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title).font(PawlyFont.bodyLarge).foregroundStyle(PawlyColors.ink)
                    Text(reminder.recurrence.displayDescription)
                        .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
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
