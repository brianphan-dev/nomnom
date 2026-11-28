import CoreGraphics
import Foundation
import ImageIO
import NomNomShared
import UniformTypeIdentifiers

// MARK: - Models & Errors

public enum PhotoProcessingError: Error, Sendable, Equatable, LocalizedError {
    case invalidImageData
    case downsampleFailed
    case encodingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            "The provided data could not be decoded as a valid image."
        case .downsampleFailed:
            "Failed to resize the meal photo."
        case .encodingFailed:
            "Failed to encode the processed meal photo."
        }
    }
}

/// A resized, EXIF-GPS-stripped image payload with content hash and dimensions.
public struct ProcessedPhoto: Sendable, Equatable {
    public var data: Data
    public var mimeType: String
    public var widthPx: Int
    public var heightPx: Int
    public var sha256Hex: String
    public var byteSize: Int64

    public init(
        data: Data,
        mimeType: String,
        widthPx: Int,
        heightPx: Int,
        sha256Hex: String
    ) {
        self.data = data
        self.mimeType = mimeType
        self.widthPx = widthPx
        self.heightPx = heightPx
        self.sha256Hex = sha256Hex
        self.byteSize = Int64(data.count)
    }
}

/// Pair of processed derivatives created from a captured meal photo.
public struct ProcessedMealPhotoBundle: Sendable, Equatable {
    /// Archival photo (max 1200px long edge, EXIF GPS stripped) stored locally & synced to R2.
    public var archival: ProcessedPhoto
    /// Vision AI analysis upload (max 768px long edge JPEG, EXIF GPS stripped).
    public var visionAI: ProcessedPhoto

    public init(archival: ProcessedPhoto, visionAI: ProcessedPhoto) {
        self.archival = archival
        self.visionAI = visionAI
    }
}

// MARK: - Photo Processor

/// On-device ImageIO / CoreGraphics processor that normalizes orientation, resizes images,
/// strips EXIF GPS / camera metadata, and computes deterministic SHA-256 hashes.
public enum PhotoProcessor: Sendable {
    public static let archivalMaxLongEdgePx: Int = 1200
    public static let visionAIMaxLongEdgePx: Int = 768
    public static let defaultArchivalQuality: Double = 0.82
    public static let defaultVisionAIQuality: Double = 0.78

    /// Produces both an archival copy (<= 1200px) and a Vision AI JPEG copy (<= 768px),
    /// with EXIF GPS metadata stripped from both outputs.
    public static func processMealPhoto(
        _ rawData: Data,
        preferHEICForArchival: Bool = true,
        archivalQuality: Double = defaultArchivalQuality,
        visionAIQuality: Double = defaultVisionAIQuality
    ) throws -> ProcessedMealPhotoBundle {
        let archival = try prepareArchivalCopy(
            from: rawData,
            maxLongEdgePx: archivalMaxLongEdgePx,
            preferHEIC: preferHEICForArchival,
            compressionQuality: archivalQuality
        )
        let visionAI = try prepareVisionAICopy(
            from: rawData,
            maxLongEdgePx: visionAIMaxLongEdgePx,
            compressionQuality: visionAIQuality
        )
        return ProcessedMealPhotoBundle(archival: archival, visionAI: visionAI)
    }

    /// Creates a resized archival copy (max 1200px long edge) with EXIF GPS stripped.
    public static func prepareArchivalCopy(
        from rawData: Data,
        maxLongEdgePx: Int = archivalMaxLongEdgePx,
        preferHEIC: Bool = true,
        compressionQuality: Double = defaultArchivalQuality
    ) throws -> ProcessedPhoto {
        let cgImage = try decodeOrientedCGImage(from: rawData, maxLongEdgePx: maxLongEdgePx)

        if preferHEIC,
           let heicData = encodeStrippedImage(
               cgImage,
               utTypeIdentifier: UTType.heic.identifier as CFString,
               compressionQuality: compressionQuality
           )
        {
            return ProcessedPhoto(
                data: heicData,
                mimeType: "image/heic",
                widthPx: cgImage.width,
                heightPx: cgImage.height,
                sha256Hex: PureSHA256.hex(heicData)
            )
        }

        guard let jpegData = encodeStrippedImage(
            cgImage,
            utTypeIdentifier: UTType.jpeg.identifier as CFString,
            compressionQuality: compressionQuality
        ) else {
            throw PhotoProcessingError.encodingFailed
        }

        return ProcessedPhoto(
            data: jpegData,
            mimeType: "image/jpeg",
            widthPx: cgImage.width,
            heightPx: cgImage.height,
            sha256Hex: PureSHA256.hex(jpegData)
        )
    }

    /// Creates a Vision AI upload JPEG copy (max 768px long edge) with EXIF GPS stripped
    /// and returns `ProcessedPhoto` including `data` and `PureSHA256.hex`.
    public static func prepareVisionAICopy(
        from rawData: Data,
        maxLongEdgePx: Int = visionAIMaxLongEdgePx,
        compressionQuality: Double = defaultVisionAIQuality
    ) throws -> ProcessedPhoto {
        let cgImage = try decodeOrientedCGImage(from: rawData, maxLongEdgePx: maxLongEdgePx)
        guard let jpegData = encodeStrippedImage(
            cgImage,
            utTypeIdentifier: UTType.jpeg.identifier as CFString,
            compressionQuality: compressionQuality
        ) else {
            throw PhotoProcessingError.encodingFailed
        }

        return ProcessedPhoto(
            data: jpegData,
            mimeType: "image/jpeg",
            widthPx: cgImage.width,
            heightPx: cgImage.height,
            sha256Hex: PureSHA256.hex(jpegData)
        )
    }

    // MARK: - Private ImageIO Helpers

    private static func decodeOrientedCGImage(from rawData: Data, maxLongEdgePx: Int) throws -> CGImage {
        guard !rawData.isEmpty else {
            throw PhotoProcessingError.invalidImageData
        }

        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
        ]
        guard let imageSource = CGImageSourceCreateWithData(rawData as CFData, sourceOptions as CFDictionary),
              CGImageSourceGetCount(imageSource) > 0
        else {
            throw PhotoProcessingError.invalidImageData
        }

        let targetMaxPixel: Int
        if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
           let pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int,
           let pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int,
           pixelWidth > 0,
           pixelHeight > 0
        {
            let originalLongEdge = max(pixelWidth, pixelHeight)
            targetMaxPixel = min(originalLongEdge, max(1, maxLongEdgePx))
        } else {
            targetMaxPixel = max(1, maxLongEdgePx)
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: targetMaxPixel,
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            throw PhotoProcessingError.downsampleFailed
        }

        return thumbnail
    }

    private static func encodeStrippedImage(
        _ cgImage: CGImage,
        utTypeIdentifier: CFString,
        compressionQuality: Double
    ) -> Data? {
        let clampedQuality = min(1.0, max(0.1, compressionQuality))
        let mutableData = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            utTypeIdentifier,
            1,
            nil
        ) else {
            return nil
        }

        // Encoding directly from a rendered CGImage with explicit null metadata dictionaries
        // removes all EXIF GPS, camera, TIFF, and IPTC metadata.
        let destinationProperties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: clampedQuality,
            kCGImagePropertyGPSDictionary: kCFNull as Any,
            kCGImagePropertyExifAuxDictionary: kCFNull as Any,
            kCGImagePropertyIPTCDictionary: kCFNull as Any,
            kCGImagePropertyOrientation: 1,
        ]

        CGImageDestinationAddImage(destination, cgImage, destinationProperties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return mutableData as Data
    }
}
