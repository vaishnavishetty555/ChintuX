import SwiftUI
import SwiftData

/// PRD — Travel paperwork generator. Paid feature that creates a PDF summary
/// of pet identity + selected documents for travel.
struct TravelPaperworkSheet: View {
    let pet: Pet?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscription = SubscriptionStore.shared

    @Query(sort: [SortDescriptor(\PetDocument.createdAt, order: .reverse)])
    private var allDocuments: [PetDocument]

    @State private var selectedPet: Pet?
    @State private var destination: String = ""
    @State private var isInternational = false
    @State private var departureDate = Date()
    @State private var ownerName: String = ""
    @State private var ownerPhone: String = ""
    @State private var ownerEmail: String = ""
    @State private var selectedDocumentIDs: Set<UUID> = []
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?

    private var eligibleDocuments: [PetDocument] {
        let base = selectedPet != nil
            ? allDocuments.filter { $0.pet?.id == selectedPet?.id }
            : allDocuments
        return base.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            Form {
                if !subscription.isPaid {
                    Section {
                        HStack(spacing: Spacing.s) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(PawlyColors.peach)
                            Text("Travel paperwork is a paid feature. Upgrade to generate travel PDFs.")
                                .font(PawlyFont.caption)
                        }
                    }
                }

                Section("Pet") {
                    if let pet {
                        Text(pet.name)
                            .font(PawlyFont.bodyMedium)
                    } else {
                        // In a global vault without a pre-selected pet, we'd need a picker.
                        // V1: show a message since the global vault always passes a pet from profile.
                        Text("Select a pet profile first to generate travel paperwork.")
                            .font(PawlyFont.caption)
                            .foregroundStyle(PawlyColors.slate)
                    }
                }

                Section("Travel Details") {
                    TextField("Destination", text: $destination)
                    Toggle("International", isOn: $isInternational)
                    DatePicker("Departure", selection: $departureDate, displayedComponents: .date)
                }

                Section("Owner Contact") {
                    TextField("Full name", text: $ownerName)
                    TextField("Phone", text: $ownerPhone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $ownerEmail)
                        .keyboardType(.emailAddress)
                }

                Section("Include Documents") {
                    if eligibleDocuments.isEmpty {
                        Text("No documents available for this pet.")
                            .font(PawlyFont.caption)
                            .foregroundStyle(PawlyColors.slate)
                    } else {
                        ForEach(eligibleDocuments) { doc in
                            Toggle(isOn: binding(for: doc.id)) {
                                HStack(spacing: Spacing.s) {
                                    Image(systemName: doc.documentType.sfSymbol)
                                        .foregroundStyle(PawlyColors.forest)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(doc.title)
                                            .font(PawlyFont.bodyMedium)
                                        Text(doc.documentType.displayName)
                                            .font(PawlyFont.captionSmall)
                                            .foregroundStyle(PawlyColors.slate)
                                    }
                                }
                            }
                            .tint(PawlyColors.forest)
                        }
                    }
                }

                Section {
                    Button {
                        generate()
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.arrow.up")
                            Text("Generate Travel PDF")
                        }
                    }
                    .disabled(!canGenerate)
                }
            }
            .navigationTitle("Travel Paperwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdfURL {
                    ShareSheet(items: [pdfURL])
                }
            }
            .onAppear {
                selectedPet = pet
            }
        }
    }

    private var canGenerate: Bool {
        subscription.isPaid
            && selectedPet != nil
            && !destination.isEmpty
            && !ownerName.isEmpty
            && !selectedDocumentIDs.isEmpty
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedDocumentIDs.contains(id) },
            set: { isOn in
                if isOn {
                    selectedDocumentIDs.insert(id)
                } else {
                    selectedDocumentIDs.remove(id)
                }
            }
        )
    }

    private func generate() {
        guard let selectedPet else { return }
        let selectedDocs = eligibleDocuments.filter { selectedDocumentIDs.contains($0.id) }
        let context = TravelPaperworkService.TravelContext(
            pet: selectedPet,
            documents: selectedDocs,
            ownerName: ownerName,
            ownerPhone: ownerPhone,
            ownerEmail: ownerEmail,
            destination: destination,
            isInternational: isInternational,
            departureDate: departureDate
        )
        if let url = TravelPaperworkService.generatePDF(context: context) {
            pdfURL = url
            showingShareSheet = true
        }
    }
}
