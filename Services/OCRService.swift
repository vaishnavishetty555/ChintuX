import Foundation
import Vision
import UIKit

/// PRD — Pet Vault OCR. Extracts text from document images using the Vision
/// framework. Available on iOS 13+; accuracy is best-effort for V1.
enum OCRService {
    /// Performs OCR on a UIImage and returns the concatenated recognized text.
    static func recognizeText(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            let strings = observations.compactMap { $0.topCandidates(1).first?.string }
            completion(strings.joined(separator: "\n"))
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(nil)
            }
        }
    }
}
