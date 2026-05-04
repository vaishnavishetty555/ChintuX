import SwiftUI
import SwiftData
import PhotosUI

/// Pet Vault home — encrypted document storage with modern, polished UI.
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
            VStack(alignment: .leading, spacing: Spacing.l) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pet Vault")
                        .font(PawlyFont.displayLarge)
                        .foregroundStyle(PawlyColors.ink)
                    Text("Secure storage for certificates, bills, and travel papers.")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.m)

                if !subscription.isPaid {
                    tierBanner
                }

                if !expiringSoon.isEmpty {
                    expirySection
                }

                // Filter bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: filterType == nil) { filterType = nil }
                        ForEach(DocumentType.allCases) { type in
                            FilterChip(title: type.displayName, isSelected: filterType == type) {
                                filterType = type
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                }

                documentList

                Spacer(minLength: Spacing.xxl)
            }
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

    // MARK: - Tier Banner

    private var tierBanner: some View {
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
            Text("Upgrade for unlimited storage, OCR search, and travel paperwork.")
                .font(PawlyFont.caption)
                .foregroundStyle(PawlyColors.slate)
            Button("Upgrade") { showingPaywall = true }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .fill(PawlyColors.forest)
                )
                .padding(.top, 4)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.peachLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(PawlyColors.peach.opacity(0.3), lineWidth: 0.75)
        )
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Expiry Section

    private var expirySection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(PawlyColors.alert)
                Text("Expiring soon")
                    .font(PawlyFont.headingMedium)
                    .foregroundStyle(PawlyColors.alert)
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            ForEach(expiringSoon) { doc in
                Button { selectedDocument = doc } label: {
                    ExpiryRow(document: doc)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }

    // MARK: - Document List

    @ViewBuilder
    private var documentList: some View {
        if documents.isEmpty {
            VStack(spacing: Spacing.m) {
                ZStack {
                    Circle().fill(PawlyColors.forestLight).frame(width: 72, height: 72)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(PawlyColors.forest)
                }
                VStack(spacing: 4) {
                    Text("No documents yet")
                        .font(PawlyFont.headingMedium)
                        .foregroundStyle(PawlyColors.ink)
                    Text("Tap + to add vaccination cards, bills, or passports.")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
        } else {
            ForEach(documents) { doc in
                Button { selectedDocument = doc } label: {
                    DocumentRow(document: doc)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }
}

// MARK: - Document Row

private struct DocumentRow: View {
    let document: PetDocument

    var body: some View {
        HStack(spacing: Spacing.m) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: Radius.small)
                    .fill(PawlyColors.forestLight)
                    .frame(width: 48, height: 48)
                if let thumb = document.thumbnailData, let ui = UIImage(data: thumb) {
                    Image(uiImage: ui)
                        .resizable().scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
                } else {
                    Image(systemName: document.documentType.sfSymbol)
                        .font(.system(size: 20))
                        .foregroundStyle(PawlyColors.forest)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(document.title)
                        .font(PawlyFont.bodyLarge)
                        .foregroundStyle(PawlyColors.ink)
                    if document.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(PawlyColors.peach)
                    }
                }
                Text(document.documentType.displayName)
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.slate)
                if let days = document.daysUntilExpiry {
                    let label = days < 0 ? "Expired \(abs(days))d ago" : "Expires in \(days)d"
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(days < 0 ? PawlyColors.alert : PawlyColors.peach)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PawlyColors.sand)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(PawlyColors.sand.opacity(0.4), lineWidth: 0.75)
        )
    }
}

// MARK: - Expiry Row

private struct ExpiryRow: View {
    let document: PetDocument

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: document.documentType.sfSymbol)
                .foregroundStyle(PawlyColors.alert)
                .frame(width: 36, height: 36)
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
        .padding(Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .stroke(PawlyColors.alert.opacity(0.2), lineWidth: 0.75)
        )
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? PawlyColors.forest : PawlyColors.surface)
                )
                .overlay(
                    Capsule().stroke(isSelected ? PawlyColors.forest : PawlyColors.sand.opacity(0.5), lineWidth: 0.75)
                )
                .foregroundStyle(isSelected ? .white : PawlyColors.ink)
        }
        .buttonStyle(.plain)
    }
}