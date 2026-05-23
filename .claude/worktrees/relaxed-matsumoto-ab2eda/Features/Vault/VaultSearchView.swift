import SwiftUI
import SwiftData

/// PRD — Pet Vault OCR search. Paid feature that searches across OCR text,
/// titles, and notes for all documents.
struct VaultSearchView: View {
    let pet: Pet?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscription = SubscriptionStore.shared

    @Query(sort: [SortDescriptor(\PetDocument.createdAt, order: .reverse)])
    private var allDocuments: [PetDocument]

    @State private var query: String = ""

    private var documents: [PetDocument] {
        let base = pet != nil
            ? allDocuments.filter { $0.pet?.id == pet?.id }
            : allDocuments
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
            || $0.notes.localizedCaseInsensitiveContains(trimmed)
            || ($0.ocrText ?? "").localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !subscription.isPaid {
                    Section {
                        PawlyCard {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("OCR Search is a paid feature")
                                    .font(PawlyFont.headingMedium)
                                Text("Upgrade to search inside scanned documents.")
                                    .font(PawlyFont.bodyMedium)
                                    .foregroundStyle(PawlyColors.slate)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }

                ForEach(documents) { doc in
                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                        HStack(spacing: Spacing.m) {
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
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search Documents")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
