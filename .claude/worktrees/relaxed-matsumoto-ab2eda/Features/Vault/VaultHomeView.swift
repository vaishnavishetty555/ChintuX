import SwiftUI
import SwiftData

/// Pet Vault home — encrypted document storage with warm pastel design.
struct VaultHomeView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    @State private var showingUpload = false
    @State private var showingSearch = false
    @State private var showingTravel = false
    @State private var showingPaywall = false
    @State private var selectedDocument: PetDocument?
    @State private var filterType: DocumentType?
    @StateObject private var subscription = SubscriptionStore.shared

    @Query(sort: [SortDescriptor(\PetDocument.createdAt, order: .reverse)])
    private var allDocuments: [PetDocument]

    private var activePet: PetDTO? {
        dataStore.pets.first { $0.id == petContext.activePetID } ?? dataStore.pets.first
    }

    private var documents: [PetDocument] {
        let base = activePet != nil
            ? allDocuments.filter { $0.pet?.id.uuidString == activePet?.id.uuidString }
            : allDocuments
        if let filterType {
            return base.filter { $0.documentType == filterType }
        }
        return base
    }

    private var expiringSoon: [PetDocument] {
        documents.filter { $0.isExpiringSoon }
    }

    // Vault categories for the design
    private let vaultCategories: [(id: String, label: String, icon: String, tone: Int)] = [
        ("vacc",  "Vaccinations",    "shield.fill",    1),
        ("rx",    "Prescriptions",   "pills.fill",     0),
        ("lab",   "Lab & X-rays",    "doc.fill",       4),
        ("ins",   "Insurance",       "shield.fill",    2),
        ("own",   "Ownership",       "doc.fill",        5),
        ("chip",  "Microchip",       "lock.fill",       6),
    ]

    private func documentTypeRaw(for catId: String) -> String {
        switch catId {
        case "vacc": return "vaccinationCertificate"
        case "rx":   return "other"
        case "lab":  return "vetBill"
        case "ins":  return "insurance"
        case "own":  return "breederPapers"
        case "chip": return "microchipDetails"
        default:     return "other"
        }
    }

    private func headerTitleString(for pet: PetDTO?) -> String {
        if let pet = pet {
            return "\(pet.name)'s encrypted documents"
        }
        return "End-to-end encrypted. Sync across vet visits."
    }

    private func resolveSwiftDataPet() -> Pet? {
        guard let activePet else { return nil }
        let descriptor = FetchDescriptor<Pet>(
            predicate: #Predicate { $0.id == activePet.id }
        )
        return try? PreviewSupport.sharedContext.fetch(descriptor).first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Pet selector
                if dataStore.pets.count > 1 {
                    PetSelectorRow(pets: dataStore.pets, selectedId: petContext.activePetID) { newId in
                        petContext.setActive(dataStore.pets.first { $0.id == newId }!)
                    } onAdd: {}
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.m)
                }

                // Header
                let headerTitle = headerTitleString(for: activePet)
                HeaderSection(title: headerTitle)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)

                // Trust strip
                TrustStripView()
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)

                // Categories grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("Categories")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.l)
                        .padding(.bottom, 4)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(vaultCategories, id: \.id) { cat in
                            VaultCategoryCell2(
                                cat: cat,
                                documents: documents,
                                documentTypeRaw: documentTypeRaw
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                }

                // Document list
                if !documents.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        // Document list header
                        DocumentListHeader()
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.top, Spacing.l)

                        VStack(spacing: 8) {
                            ForEach(documents.prefix(3)) { doc in
                                DocumentRowButton(
                                    doc: doc,
                                    selectedDocument: $selectedDocument
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                    }
                }

                // Empty state
                if documents.isEmpty {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(PawlyColors.peachAccentSoft)
                                .frame(width: 72, height: 72)
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(PawlyColors.peachAccent)
                        }
                        VStack(spacing: 4) {
                            Text("No documents yet")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(PawlyColors.ink)
                            Text("Tap upload to add vaccination cards, bills, or passports.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PawlyColors.inkSoft)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
                    .padding(.horizontal, Spacing.screenHorizontal)
                }

                Color.clear.frame(height: 120)
            }
        }
        .background(PawlyColors.pastelBg.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .navigationTitle(activePet != nil ? "\(activePet!.name)'s Vault" : "Pet Vault")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingSearch = true } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    Button { showingTravel = true } label: {
                        Label("Travel Paperwork", systemImage: "airplane")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .tint(PawlyColors.peachAccent)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if subscription.canAddDocument {
                        showingUpload = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .tint(PawlyColors.peachAccent)
            }
        }
        .sheet(isPresented: $showingUpload) {
            VaultUploadSheetWrapper(activePet: activePet)
        }
        .sheet(isPresented: $showingSearch) {
            VaultSearchView(pet: nil)
        }
        .sheet(isPresented: $showingTravel) {
            TravelPaperworkSheet(pet: nil)
        }
        .sheet(isPresented: $showingPaywall) {
            SubscriptionPaywallView()
        }
        .sheet(item: $selectedDocument) { doc in
            DocumentDetailView(document: doc)
        }
        .onAppear { subscription.updateDocumentCount(allDocuments.count) }
        .onChange(of: allDocuments.count) { _, newCount in
            subscription.updateDocumentCount(newCount)
        }
    }
}

struct VaultCategoryCell2: View {
    let cat: (id: String, label: String, icon: String, tone: Int)
    let documents: [PetDocument]
    let documentTypeRaw: (String) -> String

    var body: some View {
        let docType = documentTypeRaw(cat.id)
        let count = documents.filter { $0.documentTypeRaw == docType }.count
        return PBGVaultCategoryCard(
            label: cat.label,
            icon: cat.icon,
            tone: cat.tone,
            count: count
        )
    }
}

private struct HeaderSection: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pet vault")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft)
        }
    }
}

private struct TrustStripView: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#FFD685"))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("End-to-end encrypted")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "#FFFBF3"))
                Text("Sync across vet visits, share with one tap")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color(hex: "#2A2520"))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
        )
    }
}

private struct DocumentListHeader: View {
    var body: some View {
        HStack {
            Text("Recent uploads")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
            Spacer()
            Button { } label: {
                Text("View all")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct DocumentRowButton: View {
    let doc: PetDocument
    @Binding var selectedDocument: PetDocument?

    var body: some View {
        let dateText = doc.createdAt.formatted(.dateTime.month().day().year())
        let docSymbol = doc.documentType.sfSymbol
        Button { selectedDocument = doc } label: {
            PBGDocRow(
                name: doc.title,
                from: "Uploaded",
                date: dateText,
                size: "—",
                icon: docSymbol,
                tone: 1
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Vault") {
    NavigationStack { VaultHomeView() }
        .modelContainer(PreviewSupport.container)
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}