import SwiftUI
import PhotosUI

extension Image {
    /// Best-effort load from JPEG/PNG data; returns a paw placeholder if nil/invalid.
    static func fromPhotoData(_ data: Data?) -> Image {
        if let data, let ui = UIImage(data: data) {
            return Image(uiImage: ui)
        }
        return Image(systemName: "pawprint.fill")
    }
}

extension UIImage {
    /// Compress to ~1MB JPEG data for SwiftData storage.
    func compressedJPEGData(maxBytes: Int = 1_000_000, initialQuality: CGFloat = 0.8) -> Data? {
        var quality = initialQuality
        var data = jpegData(compressionQuality: quality)
        while let d = data, d.count > maxBytes, quality > 0.2 {
            quality -= 0.1
            data = jpegData(compressionQuality: quality)
        }
        return data
    }
}

/// A SwiftUI wrapper around `PhotosPicker` that returns compressed JPEG data.
struct PhotoPickerButton<Label: View>: View {
    @Binding var data: Data?
    @ViewBuilder var label: () -> Label

    @State private var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
            label()
        }
        .onChange(of: selection) { _, newItem in
            guard let newItem else { return }
            Task {
                if let raw = try? await newItem.loadTransferable(type: Data.self),
                   let ui = UIImage(data: raw),
                   let compressed = ui.compressedJPEGData() {
                    await MainActor.run { self.data = compressed }
                }
            }
        }
    }
}
