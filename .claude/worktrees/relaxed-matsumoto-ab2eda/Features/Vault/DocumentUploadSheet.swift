import SwiftUI
import SwiftData
import PhotosUI

/// PRD — Upload or edit a vault document. Encrypts image data on save.
struct DocumentUploadSheet: View {
    let pet: Pet?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscription = SubscriptionStore.shared

    @State private var title: String = ""
    @State private var documentType: DocumentType = .other
    @State private var notes: String = ""
    @State private var expiryDate: Date = Date()
    @State private var hasExpiry: Bool = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    photoSection

                    PawlyTextField(label: "Title", text: $title, placeholder: "Rabies Certificate")
                        .textInputAutocapitalization(.sentences)

                    typePicker

                    Toggle("Has expiry date", isOn: $hasExpiry)
                        .tint(PawlyColors.forest)
                    if hasExpiry {
                        DatePicker("Expiry", selection: $expiryDate, displayedComponents: .date)
                            .tint(PawlyColors.forest)
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

                    if !subscription.isPaid {
                        PawlyCard {
                            HStack(spacing: Spacing.s) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(PawlyColors.peach)
                                Text("Upgrade to unlock OCR text extraction and automatic expiry reminders.")
                                    .font(PawlyFont.caption)
                                    .foregroundStyle(PawlyColors.slate)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.l)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationTitle("New Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || imageData == nil || isProcessing)
                        .tint(PawlyColors.forest)
                }
            }
            .onChange(of: selectedPhoto) { _, _ in loadPhoto() }
        }
    }

    // MARK: - Photo section

    private var photoSection: some View {
        VStack(spacing: Spacing.s) {
            if let imageData, let ui = UIImage(data: imageData) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .stroke(PawlyColors.sand, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(PawlyColors.surface)
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: Spacing.s) {
                            Image(systemName: "doc.viewfinder.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(PawlyColors.slate)
                            Text("Tap to select a document photo")
                                .font(PawlyFont.bodyMedium)
                                .foregroundStyle(PawlyColors.slate)
                        }
                    )
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack {
                    Image(systemName: "photo")
                    Text(imageData == nil ? "Choose photo" : "Change photo")
                }
                .font(PawlyFont.bodyMedium)
                .foregroundStyle(PawlyColors.forest)
                .padding(.vertical, Spacing.s)
            }
        }
    }

    // MARK: - Type picker

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Document type").font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
            Picker("Type", selection: $documentType) {
                ForEach(DocumentType.allCases) { t in
                    Label(t.displayName, systemImage: t.sfSymbol).tag(t)
                }
            }
            .pickerStyle(.menu)
            .tint(PawlyColors.forest)
        }
    }

    // MARK: - Save

    private func loadPhoto() {
        Task {
            guard let selectedPhoto else { return }
            if let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
                await MainActor.run { self.imageData = data }
            }
        }
    }

    private func save() {
        guard let imageData else { return }
        isProcessing = true

        Task {
            // Encrypt
            let encrypted = DocumentEncryptionService.encrypt(data: imageData)

            // Thumbnail
            let thumbnail: Data? = await Task.detached {
                guard let ui = UIImage(data: imageData) else { return nil }
                let size = CGSize(width: 200, height: 200)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                ui.draw(in: CGRect(origin: .zero, size: size))
                let scaled = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return scaled?.jpegData(compressionQuality: 0.6)
            }.value

            // OCR (paid)
            var ocr: String?
            if subscription.isPaid, let ui = UIImage(data: imageData) {
                ocr = await withCheckedContinuation { continuation in
                    OCRService.recognizeText(from: ui) { text in
                        continuation.resume(returning: text)
                    }
                }
            }

            await MainActor.run {
                let doc = PetDocument(
                    pet: pet,
                    title: title.trimmingCharacters(in: .whitespaces),
                    documentType: documentType,
                    encryptedData: encrypted,
                    thumbnailData: thumbnail,
                    ocrText: ocr,
                    expiryDate: hasExpiry ? expiryDate : nil,
                    notes: notes
                )
                modelContext.insert(doc)
                try? modelContext.save()

                // Schedule expiry reminder if paid
                if subscription.isPaid, let expiry = hasExpiry ? expiryDate : nil {
                    scheduleExpiryReminder(for: doc, expiry: expiry)
                }

                isProcessing = false
                dismiss()
            }
        }
    }

    private func scheduleExpiryReminder(for document: PetDocument, expiry: Date) {
        guard let pet = document.pet else { return }
        let reminderDate = expiry.addingTimeInterval(-7 * 24 * 60 * 60) // 7 days before
        guard reminderDate > .now else { return }
        NotificationService.schedule(
            reminderInstanceID: document.id,
            reminderID: document.id,
            petName: pet.name,
            title: "\(document.title) expiring soon",
            body: "\(pet.name)'s \(document.documentType.displayName.lowercased()) expires in 7 days.",
            fireDate: reminderDate
        )
    }
}
