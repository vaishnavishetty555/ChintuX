import SwiftUI
import SwiftData

struct VaultHomeView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    @State private var showingUpload = false
    @State private var showingSearch = false
    @State private var showingTravel = false
    @State private var showingPaywall = false
    @State private var selectedDocument: PetDocument?
    @State private var shareItems: [Any] = []
    @State private var showingShare = false
    @StateObject private var subscription = SubscriptionStore.shared

    @Query(sort: [SortDescriptor(\PetDocument.createdAt, order: .reverse)])
    private var allDocuments: [PetDocument]

    private var activePet: PetDTO? {
        dataStore.pets.first { $0.id == petContext.activePetID } ?? dataStore.pets.first
    }

    private var documents: [PetDocument] {
        activePet != nil
            ? allDocuments.filter { $0.pet?.id.uuidString == activePet?.id.uuidString }
            : allDocuments
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Pet selector — only when multi-pet
                if dataStore.pets.count > 1 {
                    PetSelectorRow(pets: dataStore.pets, selectedId: petContext.activePetID) { newId in
                        petContext.setActive(dataStore.pets.first { $0.id == newId }!)
                    } onAdd: {}
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)
                }

                // Encryption badge
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(PawlyColors.forest)
                    Text("End-to-end encrypted")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PawlyColors.forest)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(PawlyColors.forest.opacity(0.10)))
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)

                if documents.isEmpty {
                    emptyState
                } else {
                    documentList
                }

                Color.clear.frame(height: 120)
            }
        }
        .background(PawlyColors.canvas.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .navigationTitle(activePet.map { "\($0.name)'s Vault" } ?? "Vault")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingSearch = true } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    Button { showingTravel = true } label: {
                        Label("Travel Paperwork", systemImage: "airplane")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if subscription.canAddDocument { showingUpload = true }
                    else { showingPaywall = true }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingUpload)  { VaultUploadSheetWrapper(activePet: activePet) }
        .sheet(isPresented: $showingSearch)  { VaultSearchView(pet: nil) }
        .sheet(isPresented: $showingTravel)  { TravelPaperworkSheet(pet: nil) }
        .sheet(isPresented: $showingPaywall) { SubscriptionPaywallView() }
        .sheet(item: $selectedDocument)      { DocumentDetailView(document: $0) }
        .sheet(isPresented: $showingShare)   { ShareSheet(items: shareItems) }
        .onAppear { subscription.updateDocumentCount(allDocuments.count) }
        .onChange(of: allDocuments.count) { _, n in subscription.updateDocumentCount(n) }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(PawlyColors.forest.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.doc")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(PawlyColors.forest)
            }

            VStack(spacing: 6) {
                Text("No documents yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PawlyColors.ink)
                Text("Store vaccinations, prescriptions, insurance\ncards, lab reports and more.")
                    .font(.system(size: 14))
                    .foregroundStyle(PawlyColors.slate)
                    .multilineTextAlignment(.center)
            }

            Button {
                if subscription.canAddDocument { showingUpload = true }
                else { showingPaywall = true }
            } label: {
                Label("Add Document", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(PawlyColors.forest))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Document List

    private var documentList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(documents.count) document\(documents.count == 1 ? "" : "s")")
                    .font(PawlyFont.overline)
                    .foregroundStyle(PawlyColors.slate)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.l)

            VStack(spacing: 8) {
                ForEach(documents) { doc in
                    Button { selectedDocument = doc } label: {
                        VaultDocRow(doc: doc) {
                            shareDocument(doc)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    // MARK: - Share

    private func shareDocument(_ doc: PetDocument) {
        Task.detached {
            var items: [Any] = [doc.title]
            if let encrypted = doc.encryptedData,
               let decrypted = DocumentEncryptionService.decrypt(data: encrypted),
               let image = UIImage(data: decrypted) {
                items = [image]
            } else if let thumb = doc.thumbnailData,
                      let image = UIImage(data: thumb) {
                items = [image]
            }
            await MainActor.run {
                self.shareItems = items
                self.showingShare = true
            }
        }
    }
}

// MARK: - Vault Document Row

struct VaultDocRow: View {
    let doc: PetDocument
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(PawlyColors.forest.opacity(0.08))
                    .frame(width: 48, height: 48)
                if let thumb = doc.thumbnailData, let img = UIImage(data: thumb) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Image(systemName: doc.documentType.sfSymbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(PawlyColors.forest)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(doc.documentType.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(PawlyColors.forest)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(PawlyColors.forest.opacity(0.10)))

                    Text(doc.createdAt.formatted(.dateTime.day().month().year()))
                        .font(.system(size: 11))
                        .foregroundStyle(PawlyColors.slate)

                    if doc.isExpiringSoon {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(PawlyColors.alert)
                    }
                }
            }

            Spacer(minLength: 0)

            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PawlyColors.forest)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(PawlyColors.forest.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(PawlyColors.hairline, lineWidth: 0.75)
        )
    }
}

#Preview("Vault") {
    NavigationStack { VaultHomeView() }
        .modelContainer(PreviewSupport.container)
        .environmentObject(PetContextStore())
        .environmentObject(DataStore.shared)
}
