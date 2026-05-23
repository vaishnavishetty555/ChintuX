import SwiftUI
import SwiftData
import LocalAuthentication

struct VaultHomeView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.modelContext) private var modelContext

    @State private var showingUpload = false
    @State private var showingSearch = false
    @State private var showingTravel = false
    @State private var showingPaywall = false
    @State private var selectedDocument: PetDocument?
    @State private var shareItems: [Any] = []
    @State private var showingShare = false
    @State private var showingAuthError = false
    @State private var documentToDelete: PetDocument?
    @StateObject private var subscription = SubscriptionStore.shared

    // Used only to track total count for subscription gating
    @Query private var allDocuments: [PetDocument]

    private var activePet: PetDTO? {
        dataStore.pets.first { $0.id == petContext.activePetID } ?? dataStore.pets.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                if dataStore.pets.count > 1 {
                    PetSelectorRow(pets: dataStore.pets, selectedId: petContext.activePetID) { newId in
                        petContext.setActive(dataStore.pets.first { $0.id == newId }!)
                    } onAdd: {}
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)
                }

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

                if let petId = activePet?.id {
                    VaultPetDocuments(
                        petId: petId,
                        onTap: { doc in
                            if doc.isLocked { authenticateToOpen(doc) }
                            else { selectedDocument = doc }
                        },
                        onShare: shareDocument,
                        onDelete: { doc in documentToDelete = doc },
                        onAdd: {
                            if subscription.canAddDocument { showingUpload = true }
                            else { showingPaywall = true }
                        }
                    )
                } else {
                    noActivePetState
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
        .alert("Authentication Failed", isPresented: $showingAuthError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Face ID, Touch ID, or passcode required to open this document.")
        }
        .alert("Delete Document?", isPresented: Binding(
            get: { documentToDelete != nil },
            set: { if !$0 { documentToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let doc = documentToDelete {
                    deleteDocument(doc)
                }
            }
            Button("Cancel", role: .cancel) { documentToDelete = nil }
        } message: {
            if let doc = documentToDelete {
                Text("\"\(doc.title)\" will be permanently deleted and cannot be recovered.")
            } else {
                Text("This document will be permanently deleted and cannot be recovered.")
            }
        }
    }

    // MARK: - Delete Document

    private func deleteDocument(_ doc: PetDocument) {
        modelContext.delete(doc)
        try? modelContext.save()
        documentToDelete = nil
    }

    // MARK: - Biometric / passcode auth

    private func authenticateToOpen(_ doc: PetDocument) {
        let context = LAContext()
        let reason = "Unlock \"\(doc.title)\""
        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            selectedDocument = doc
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                if success { self.selectedDocument = doc }
                else { self.showingAuthError = true }
            }
        }
    }

    // MARK: - No active pet fallback

    private var noActivePetState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(PawlyColors.forest.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(PawlyColors.forest)
            }
            Text("No pet selected")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(PawlyColors.ink)
            Text("Select a pet to view their documents.")
                .font(.system(size: 14))
                .foregroundStyle(PawlyColors.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Share

    private func shareDocument(_ doc: PetDocument) {
        Task.detached {
            let items: [Any]
            if let encrypted = doc.encryptedData,
               let decrypted = DocumentEncryptionService.decrypt(data: encrypted),
               let image = UIImage(data: decrypted) {
                items = [image]
            } else if let thumb = doc.thumbnailData,
                      let image = UIImage(data: thumb) {
                items = [image]
            } else {
                items = [doc.title]
            }
            await MainActor.run {
                self.shareItems = items
                if !items.isEmpty { self.showingShare = true }
            }
        }
    }
}

// MARK: - Pet-scoped document list (predicate @Query refreshes automatically on insert)

private struct VaultPetDocuments: View {
    let petId: UUID
    let onTap: (PetDocument) -> Void
    let onShare: (PetDocument) -> Void
    let onDelete: (PetDocument) -> Void
    let onAdd: () -> Void

    @Query private var documents: [PetDocument]

    init(
        petId: UUID,
        onTap: @escaping (PetDocument) -> Void,
        onShare: @escaping (PetDocument) -> Void,
        onDelete: @escaping (PetDocument) -> Void,
        onAdd: @escaping () -> Void
    ) {
        self.petId = petId
        self.onTap = onTap
        self.onShare = onShare
        self.onDelete = onDelete
        self.onAdd = onAdd
        _documents = Query(
            filter: #Predicate<PetDocument> { doc in
                doc.petId == petId
            },
            sort: \PetDocument.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        if documents.isEmpty {
            emptyState
        } else {
            documentList
        }
    }

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

            Button(action: onAdd) {
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
                    Button { onTap(doc) } label: {
                        VaultDocRow(doc: doc) { onShare(doc) }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDelete(doc)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }
}

// MARK: - Vault Document Row

struct VaultDocRow: View {
    let doc: PetDocument
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
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
                if doc.isLocked {
                    ZStack {
                        Circle()
                            .fill(PawlyColors.forest)
                            .frame(width: 16, height: 16)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 4, y: 4)
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
