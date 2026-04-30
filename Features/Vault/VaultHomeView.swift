import SwiftUI
import SwiftData
import PhotosUI

/// PRD — Pet Vault home. Lists encrypted documents per-pet or globally.
/// Free tier caps at 10 documents. Paid unlocks unlimited, OCR search,
/// expiry reminders, and travel paperwork.
struct VaultHomeView: View {
    let pet: Pet?

    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscription = SubscriptionStore.shared

    @Query(sort: [SortDescriptor(\PetDocument.createdAt, order: .reverse)])
    private var allDocuments: [PetDocument]

    @State private var showingUpload = false
    @State private var showingSearch = false
    @State private var showingTravel = false
    @State private var showingPaywall = false
    @State private var selectedDocument: PetDocument?
    @State private var filterType: DocumentType?

    private var documents: [PetDocument] {
        let base = pet != nil
            ? allDocuments.filter { $0.pet?.id == pet?.id }
            : allDocuments
        if let filterType {
            return base.filter { $0.documentType == filterType }
        }
        return base
    }

    private var expiringSoon: [PetDocument] {
        documents.filter { $0.isExpiringSoon }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                header

                if !subscription.isPaid {
                    tierBanner
                }

                if !expiringSoon.isEmpty {
                    expirySection
                }

                filterBar

                documentList
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.m)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle(pet?.name != nil ? "\(pet!.name)'s Vault" : "Pet Vault")
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
                        .tint(PawlyColors.forest)
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
                .tint(PawlyColors.forest)
            }
        }
        .sheet(isPresented: $showingUpload) {
            DocumentUploadSheet(pet: pet)
        }
        .sheet(isPresented: $showingSearch) {
            VaultSearchView(pet: pet)
        }
        .sheet(isPresented: $showingTravel) {
            TravelPaperworkSheet(pet: pet)
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("The Pet Vault")
                .font(PawlyFont.displayMedium)
                .foregroundStyle(PawlyColors.ink)
            Text("Secure storage for certificates, bills, and travel papers.")
                .font(PawlyFont.bodyMedium)
                .foregroundStyle(PawlyColors.slate)
        }
    }

    // MARK: - Tier banner

    private var tierBanner: some View {
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(PawlyColors.peach)
                    Text("Free plan")
                        .font(PawlyFont.headingMedium)
                        .foregroundStyle(PawlyColors.ink)
                    Spacer()
                    Text("\(allDocuments.count)/\(SubscriptionStore.freeDocumentLimit)")
                        .font(PawlyFont.caption)
                        .foregroundStyle(PawlyColors.slate)
                }
                ProgressView(value: Double(min(allDocuments.count, SubscriptionStore.freeDocumentLimit)),
                             total: Double(SubscriptionStore.freeDocumentLimit))
                .tint(PawlyColors.forest)
                Text("Upgrade for unlimited storage, OCR search, expiry reminders, and travel paperwork.")
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.slate)
                Button("Upgrade") { showingPaywall = true }
                    .buttonStyle(.pawlyPrimary)
            }
        }
    }

    // MARK: - Expiry section

    private var expirySection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Expiring soon")
                .font(PawlyFont.headingMedium)
                .foregroundStyle(PawlyColors.alert)
            ForEach(expiringSoon) { doc in
                Button { selectedDocument = doc } label: {
                    ExpiryRow(document: doc)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterType == nil) {
                    filterType = nil
                }
                ForEach(DocumentType.allCases) { type in
                    FilterChip(title: type.displayName, isSelected: filterType == type) {
                        filterType = type
                    }
                }
            }
        }
    }

    // MARK: - Document list

    @ViewBuilder
    private var documentList: some View {
        if documents.isEmpty {
            PawlyCard {
                VStack(spacing: Spacing.s) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(PawlyColors.forest)
                    Text("No documents yet")
                        .font(PawlyFont.headingMedium)
                        .foregroundStyle(PawlyColors.ink)
                    Text("Tap + to add vaccination cards, bills, or passports.")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            }
        } else {
            ForEach(documents) { doc in
                Button { selectedDocument = doc } label: {
                    DocumentRow(document: doc)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Row views

private struct DocumentRow: View {
    let document: PetDocument

    var body: some View {
        PawlyCard {
            HStack(spacing: Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.card)
                        .fill(PawlyColors.cream)
                    if let thumb = document.thumbnailData, let ui = UIImage(data: thumb) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                    } else {
                        Image(systemName: document.documentType.sfSymbol)
                            .font(.system(size: 22))
                            .foregroundStyle(PawlyColors.forest)
                    }
                }
                .frame(width: 56, height: 56)
                .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(PawlyFont.bodyLarge)
                        .foregroundStyle(PawlyColors.ink)
                    Text(document.documentType.displayName)
                        .font(PawlyFont.caption)
                        .foregroundStyle(PawlyColors.slate)
                    if let days = document.daysUntilExpiry {
                        let label = days < 0 ? "Expired \(abs(days))d ago" : "Expires in \(days)d"
                        Text(label)
                            .font(PawlyFont.captionSmall)
                            .foregroundStyle(days < 0 ? PawlyColors.alert : PawlyColors.peach)
                    }
                }
                Spacer()
                if document.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(PawlyColors.peach)
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(PawlyColors.slate)
            }
        }
    }
}

private struct ExpiryRow: View {
    let document: PetDocument

    var body: some View {
        PawlyCard {
            HStack(spacing: Spacing.m) {
                Image(systemName: document.documentType.sfSymbol)
                    .foregroundStyle(PawlyColors.alert)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(PawlyColors.alert.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.ink)
                    if let days = document.daysUntilExpiry {
                        Text(days < 0 ? "Expired \(abs(days)) days ago" : "Expires in \(days) days")
                            .font(PawlyFont.captionSmall)
                            .foregroundStyle(PawlyColors.alert)
                    }
                }
                Spacer()
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PawlyFont.caption)
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? PawlyColors.forest : PawlyColors.surface))
                .foregroundStyle(isSelected ? .white : PawlyColors.ink)
                .overlay(Capsule().stroke(PawlyColors.sand, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
