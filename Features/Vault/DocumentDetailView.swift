import SwiftUI
import SwiftData

/// PRD — View a vault document, decrypt on demand, and perform actions.
struct DocumentDetailView: View {
    let document: PetDocument

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscription = SubscriptionStore.shared

    @State private var decryptedImage: UIImage?
    @State private var showingDeleteConfirm = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    imageSection

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(document.title)
                            .font(PawlyFont.displayMedium)
                            .foregroundStyle(PawlyColors.ink)
                        Text(document.documentType.displayName)
                            .font(PawlyFont.bodyMedium)
                            .foregroundStyle(PawlyColors.slate)
                    }

                    if let days = document.daysUntilExpiry {
                        PawlyCard {
                            HStack {
                                Image(systemName: days < 0 ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
                                    .foregroundStyle(days < 0 ? PawlyColors.alert : PawlyColors.peach)
                                Text(days < 0 ? "Expired \(abs(days)) days ago" : "Expires in \(days) days")
                                    .font(PawlyFont.bodyMedium)
                                    .foregroundStyle(days < 0 ? PawlyColors.alert : PawlyColors.ink)
                                Spacer()
                            }
                        }
                    }

                    if !document.notes.isEmpty {
                        PawlyCard {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Notes").font(PawlyFont.headingMedium)
                                Text(document.notes)
                                    .font(PawlyFont.bodyMedium)
                                    .foregroundStyle(PawlyColors.slate)
                            }
                        }
                    }

                    if let ocr = document.ocrText, !ocr.isEmpty {
                        PawlyCard {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                HStack {
                                    Image(systemName: "text.viewfinder")
                                        .foregroundStyle(PawlyColors.forest)
                                    Text("OCR Text").font(PawlyFont.headingMedium)
                                }
                                Text(ocr)
                                    .font(PawlyFont.bodyMedium)
                                    .foregroundStyle(PawlyColors.slate)
                            }
                        }
                    }

                    actionButtons
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.m)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationTitle("Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Delete document?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { delete() }
            } message: {
                Text("This cannot be undone. The encrypted file will be permanently removed.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
                }
            }
            .onAppear(perform: decrypt)
        }
    }

    // MARK: - Image section

    private var imageSection: some View {
        Group {
            if let decryptedImage {
                Image(uiImage: decryptedImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .stroke(PawlyColors.sand, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(PawlyColors.surface)
                    .frame(height: 220)
                    .overlay(
                        ProgressView()
                            .tint(PawlyColors.forest)
                    )
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: Spacing.s) {
            Button {
                exportToPDF()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Document")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pawlyPrimary)

            Button {
                document.isFavorite.toggle()
                try? modelContext.save()
            } label: {
                HStack {
                    Image(systemName: document.isFavorite ? "star.slash.fill" : "star.fill")
                    Text(document.isFavorite ? "Remove from favorites" : "Add to favorites")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pawlySecondary)

            Button("Delete document", role: .destructive) {
                showingDeleteConfirm = true
            }
            .buttonStyle(.pawlyDestructive)
        }
    }

    // MARK: - Helpers

    private func decrypt() {
        guard let encrypted = document.encryptedData else { return }
        Task.detached {
            if let data = DocumentEncryptionService.decrypt(data: encrypted) {
                let image = UIImage(data: data)
                await MainActor.run { self.decryptedImage = image }
            }
        }
    }

    private func delete() {
        modelContext.delete(document)
        try? modelContext.save()
        dismiss()
    }

    private func exportToPDF() {
        guard let decryptedImage else { return }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Pawly_\(document.title)_\(Int(Date().timeIntervalSince1970)).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        do {
            try renderer.writePDF(to: tempURL) { ctx in
                ctx.beginPage()
                let imageRect = CGRect(x: 40, y: 60, width: 532, height: 532)
                decryptedImage.draw(in: imageRect)
            }
            shareURL = tempURL
            showingShareSheet = true
        } catch {
            // silently fail in V1
        }
    }
}

// MARK: - Share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
