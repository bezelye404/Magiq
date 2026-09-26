//
//  ImageWand.swift
//  Magiq
//

import AppKit
import Foundation

// MARK: - ImageWand

/// RAII wrapper around ImageMagick's `MagickWand*` C pointer.
///
/// **Linked Path Rationale:**
/// Used for low-latency operations invoked repeatedly during user sessions (thumbnails,
/// live parameter previews, interactive canvas rendering, and batch progress).
public final class ImageWand: Identifiable {
    public let id = UUID()
    public let pointer: OpaquePointer

    // MARK: - Lifecycle

    public init() throws {
        WandSession.shared.ensureInitialized()
        guard let ptr = NewMagickWand() else {
            throw MagickError.wandAllocationFailed
        }
        self.pointer = ptr
    }

    private init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        DestroyMagickWand(self.pointer)
    }

    // MARK: - Dimensions & Format

    public var width: Int {
        return MagickGetImageWidth(self.pointer)
    }

    public var height: Int {
        return MagickGetImageHeight(self.pointer)
    }

    public var format: String? {
        guard let formatCString = MagickGetImageFormat(self.pointer) else { return nil }
        defer { MagickRelinquishMemory(formatCString) }
        return String(cString: formatCString)
    }

    public var geometry: MagickGeometry {
        return MagickGeometry(width: self.width, height: self.height)
    }

    public var depth: Int {
        return Int(MagickGetImageDepth(self.pointer))
    }

    public var colorspace: String {
        let cs = MagickGetImageColorspace(self.pointer)
        return self.formatColorspace(cs)
    }

    public var metadata: ImageMetadata {
        return ImageMetadata(
            width: self.width,
            height: self.height,
            format: self.format ?? "UNKNOWN",
            colorspace: self.colorspace,
            depth: self.depth,
            properties: self.getAllImageProperties()
        )
    }

    /// Reads image metadata with zero full-buffer decode using MagickPingImage.
    public static func pingMetadata(from url: URL) throws -> ImageMetadata {
        let wand = try ImageWand()
        let status = MagickPingImage(wand.pointer, url.path)
        try wand.verifyStatus(status, operation: "MagickPingImage (\(url.lastPathComponent))")

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value
        let properties = wand.getAllImageProperties()

        return ImageMetadata(
            width: wand.width,
            height: wand.height,
            format: wand.format ?? url.pathExtension.uppercased(),
            colorspace: wand.colorspace,
            depth: wand.depth,
            fileSize: fileSize,
            properties: properties
        )
    }

    /// Creates a blank image canvas in memory with the specified dimensions and background color.
    public func createBlank(width: Int, height: Int, background: String = "white") throws {
        let pixel = try PixelWandWrapper(color: background)
        let status = MagickNewImage(self.pointer, size_t(max(1, width)), size_t(max(1, height)), pixel.pointer)
        try self.verifyStatus(status, operation: "MagickNewImage")
    }

    // MARK: - Reading & Writing

    public func read(from url: URL) throws {
        let status = MagickReadImage(self.pointer, url.path)
        try self.verifyStatus(status, operation: "MagickReadImage (\(url.lastPathComponent))")
    }

    /// Reads an image with bounded size hints to avoid decoding full-resolution buffers into RAM.
    public func readThumbnail(from url: URL, pageIndex: Int? = nil, maxBounds: MagickGeometry) throws {
        MagickSetSize(self.pointer, size_t(maxBounds.width), size_t(maxBounds.height))

        let readPath: String
        if let idx = pageIndex, idx >= 0 {
            readPath = "\(url.path)[\(idx)]"
        } else {
            readPath = url.path
        }

        let status = MagickReadImage(self.pointer, readPath)
        try self.verifyStatus(status, operation: "MagickReadImage thumbnail (\(url.lastPathComponent))")

        let currentGeom = self.geometry
        if currentGeom.width > maxBounds.width || currentGeom.height > maxBounds.height {
            let fitted = currentGeom.aspectFit(within: maxBounds)
            try self.resize(to: fitted)
        }
    }

    public func write(to url: URL) throws {
        let status = MagickWriteImage(self.pointer, url.path)
        try self.verifyStatus(status, operation: "MagickWriteImage (\(url.lastPathComponent))")
    }

    // MARK: - Multi-Page & Multi-Frame Support

    /// Returns the total number of images / pages / frames inside this wand.
    public var imageCount: Int {
        Int(MagickGetNumberImages(self.pointer))
    }

    /// Returns the active image index in the sequence (0-indexed).
    public var currentImageIndex: Int {
        Int(MagickGetIteratorIndex(self.pointer))
    }

    /// Selects the active image / page by 0-based index.
    public func selectImage(at index: Int) throws {
        let status = MagickSetIteratorIndex(self.pointer, ssize_t(index))
        try self.verifyStatus(status, operation: "MagickSetIteratorIndex (\(index))")
    }

    /// Writes all images / pages in sequence to a single multi-page file (e.g. PDF or TIFF).
    public func writeAllImages(to url: URL, adjoin: Bool = true) throws {
        let status = MagickWriteImages(self.pointer, url.path, adjoin ? MagickTrue : MagickFalse)
        try self.verifyStatus(status, operation: "MagickWriteImages (\(url.lastPathComponent))")
    }

    /// Inspects the number of pages/frames in a file with zero full-buffer decode using MagickPingImage.
    public static func pingPageCount(from url: URL) -> Int {
        do {
            let wand = try ImageWand()
            let status = MagickPingImage(wand.pointer, url.path)
            guard status != MagickFalse else { return 1 }
            return max(1, wand.imageCount)
        } catch {
            return 1
        }
    }

    // MARK: - Transformations

    public func resize(to geometry: MagickGeometry) throws {
        let status = MagickResizeImage(
            self.pointer,
            size_t(geometry.width),
            size_t(geometry.height),
            LanczosFilter
        )
        try self.verifyStatus(status, operation: "MagickResizeImage")
    }

    public func rotate(degrees: Double, background: String = "none") throws {
        let pixelWand = try PixelWandWrapper(color: background)
        let status = MagickRotateImage(self.pointer, pixelWand.pointer, degrees)
        try self.verifyStatus(status, operation: "MagickRotateImage")
    }

    public func crop(x: Int, y: Int, width: Int, height: Int) throws {
        let status = MagickCropImage(
            self.pointer,
            size_t(width),
            size_t(height),
            ssize_t(x),
            ssize_t(y)
        )
        try self.verifyStatus(status, operation: "MagickCropImage")
        MagickResetImagePage(self.pointer, "0x0+0+0")
    }

    public func setFormat(_ format: String) throws {
        let status = MagickSetImageFormat(self.pointer, format.uppercased())
        try self.verifyStatus(status, operation: "MagickSetImageFormat (\(format))")
    }

    public func setCompressionQuality(_ quality: Int) throws {
        let clampedQuality = size_t(max(1, min(100, quality)))
        let status = MagickSetImageCompressionQuality(self.pointer, clampedQuality)
        try self.verifyStatus(status, operation: "MagickSetImageCompressionQuality (\(quality))")
    }

    public func flip() throws {
        let status = MagickFlipImage(self.pointer)
        try self.verifyStatus(status, operation: "MagickFlipImage")
    }

    public func flop() throws {
        let status = MagickFlopImage(self.pointer)
        try self.verifyStatus(status, operation: "MagickFlopImage")
    }

    public func brightnessContrast(brightness: Double, contrast: Double) throws {
        let status = MagickBrightnessContrastImage(self.pointer, brightness, contrast)
        try self.verifyStatus(status, operation: "MagickBrightnessContrastImage")
    }

    public func modulate(brightness: Double = 100.0, saturation: Double = 100.0, hue: Double = 100.0) throws {
        let status = MagickModulateImage(self.pointer, brightness, saturation, hue)
        try self.verifyStatus(status, operation: "MagickModulateImage")
    }

    public func autoLevel() throws {
        let status = MagickAutoLevelImage(self.pointer)
        try self.verifyStatus(status, operation: "MagickAutoLevelImage")
    }

    public func sharpen(radius: Double = 0.0, sigma: Double = 1.0) throws {
        let status = MagickSharpenImage(self.pointer, radius, sigma)
        try self.verifyStatus(status, operation: "MagickSharpenImage")
    }

    public func blur(radius: Double = 0.0, sigma: Double = 1.0) throws {
        let status = MagickBlurImage(self.pointer, radius, sigma)
        try self.verifyStatus(status, operation: "MagickBlurImage")
    }

    public func strip() throws {
        let status = MagickStripImage(self.pointer)
        try self.verifyStatus(status, operation: "MagickStripImage")
    }

    /// Adjusts levels with black point (0...255), gamma (0.1...5.0), and white point (0...255).
    public func level(blackPoint: Double = 0.0, gamma: Double = 1.0, whitePoint: Double = 255.0) throws {
        let qRange = MagiqQuantumRange()
        let scaledBlack = (max(0.0, min(255.0, blackPoint)) / 255.0) * qRange
        let scaledWhite = (max(0.0, min(255.0, whitePoint)) / 255.0) * qRange
        let clampedGamma = max(0.01, min(10.0, gamma))

        let status = MagickLevelImage(self.pointer, scaledBlack, clampedGamma, scaledWhite)
        try self.verifyStatus(status, operation: "MagickLevelImage")
    }

    /// Adjusts gamma level.
    public func gamma(_ gammaValue: Double) throws {
        let clamped = max(0.01, min(10.0, gammaValue))
        let status = MagickGammaImage(self.pointer, clamped)
        try self.verifyStatus(status, operation: "MagickGammaImage")
    }

    /// Applies a sepia tone effect with threshold percentage (0...100%).
    public func sepiaTone(thresholdPercent: Double) throws {
        guard thresholdPercent > 0 else { return }
        let qRange = MagiqQuantumRange()
        let threshold = (max(0.0, min(100.0, thresholdPercent)) / 100.0) * qRange
        let status = MagickSepiaToneImage(self.pointer, threshold)
        try self.verifyStatus(status, operation: "MagickSepiaToneImage")
    }

    /// Inverts pixel color values.
    public func negate(grayscaleOnly: Bool = false) throws {
        let status = MagickNegateImage(self.pointer, grayscaleOnly ? MagickTrue : MagickFalse)
        try self.verifyStatus(status, operation: "MagickNegateImage")
    }

    /// Reduces high-frequency noise and speckles.
    public func despeckle() throws {
        let status = MagickDespeckleImage(self.pointer)
        try self.verifyStatus(status, operation: "MagickDespeckleImage")
    }

    /// Reduces noise using wavelet denoise algorithm.
    public func waveletDenoise(thresholdPercent: Double, softness: Double = 0.0) throws {
        guard thresholdPercent > 0 else { return }
        let threshold = (max(0.0, min(100.0, thresholdPercent)) / 100.0) * MagiqQuantumRange()
        let status = MagickWaveletDenoiseImage(self.pointer, threshold, softness)
        try self.verifyStatus(status, operation: "MagickWaveletDenoiseImage")
    }

    /// Auto-trims uniform solid border / background pixels with a given fuzz tolerance percentage (0...100%).
    public func trim(fuzzPercent: Double = 0.0) throws {
        let qRange = MagiqQuantumRange()
        let fuzz = (max(0.0, min(100.0, fuzzPercent)) / 100.0) * qRange
        let status = MagickTrimImage(self.pointer, fuzz)
        try self.verifyStatus(status, operation: "MagickTrimImage")
        MagickResetImagePage(self.pointer, "0x0+0+0")
    }

    // MARK: - Metadata Inspection

    /// Retrieves a single EXIF/IPTC or ImageMagick image property.
    public func getImageProperty(_ name: String) -> String? {
        guard let cString = MagickGetImageProperty(self.pointer, name) else { return nil }
        defer { MagickRelinquishMemory(cString) }
        return String(cString: cString)
    }

    /// Retrieves all image properties matching the given pattern (default wildcard `*`).
    public func getAllImageProperties(pattern: String = "*") -> [String: String] {
        var count: size_t = 0
        guard let keysPtr = MagickGetImageProperties(self.pointer, pattern, &count), count > 0 else {
            return [:]
        }
        defer { MagickRelinquishMemory(keysPtr) }

        var result: [String: String] = [:]
        for i in 0..<Int(count) {
            if let keyCStr = keysPtr[i] {
                let key = String(cString: keyCStr)
                if let val = self.getImageProperty(key) {
                    result[key] = val
                }
                MagickRelinquishMemory(keyCStr)
            }
        }
        return result
    }

    public func annotate(
        text: String,
        fontSize: Double = 28.0,
        color: String = "white",
        opacity: Double = 0.7,
        position: WatermarkPosition = .bottomRight
    ) throws {
        guard !text.isEmpty else { return }

        guard let drawingWand = NewDrawingWand() else {
            throw MagickError.wandAllocationFailed
        }
        defer { DestroyDrawingWand(drawingWand) }

        let pixelWand = try PixelWandWrapper(color: color)
        PixelSetAlpha(pixelWand.pointer, opacity)
        DrawSetFillColor(drawingWand, pixelWand.pointer)
        DrawSetFontSize(drawingWand, fontSize)

        let gravity: GravityType
        switch position {
        case .topLeft: gravity = NorthWestGravity
        case .topCenter: gravity = NorthGravity
        case .topRight: gravity = NorthEastGravity
        case .center: gravity = CenterGravity
        case .bottomLeft: gravity = SouthWestGravity
        case .bottomCenter: gravity = SouthGravity
        case .bottomRight: gravity = SouthEastGravity
        }
        DrawSetGravity(drawingWand, gravity)

        let status = MagickAnnotateImage(self.pointer, drawingWand, 20.0, 20.0, 0.0, text)
        try self.verifyStatus(status, operation: "MagickAnnotateImage")
    }

    public func clone() throws -> ImageWand {
        guard let clonedPtr = CloneMagickWand(self.pointer) else {
            throw MagickError.wandAllocationFailed
        }
        return ImageWand(pointer: clonedPtr)
    }

    // MARK: - Helpers

    private func formatColorspace(_ cs: ColorspaceType) -> String {
        switch cs {
        case sRGBColorspace: return "sRGB"
        case RGBColorspace: return "RGB"
        case DisplayP3Colorspace: return "Display P3"
        case Adobe98Colorspace: return "Adobe RGB (1998)"
        case GRAYColorspace, LinearGRAYColorspace: return "Grayscale"
        case CMYKColorspace: return "CMYK"
        default: return "sRGB"
        }
    }

    // MARK: - NSImage Interop

    /// Renders the current buffer directly to an NSImage for SwiftUI live previews.
    public func makeNSImage() -> NSImage? {
        guard self.width > 0, self.height > 0 else { return nil }

        return autoreleasepool {
            guard let tempWand = CloneMagickWand(self.pointer) else { return nil }
            defer { DestroyMagickWand(tempWand) }

            // Attempt TIFF export first (native macOS bitmap format, preserving full color and alpha)
            MagickSetImageFormat(tempWand, "TIFF")
            var blobLength: size_t = 0
            if let blob = MagickGetImageBlob(tempWand, &blobLength), blobLength > 0 {
                defer { MagickRelinquishMemory(blob) }
                let data = Data(bytes: blob, count: blobLength)
                if let image = NSImage(data: data) {
                    return image
                }
            }

            // Fallback to PNG
            MagickSetImageFormat(tempWand, "PNG")
            blobLength = 0
            if let blob = MagickGetImageBlob(tempWand, &blobLength), blobLength > 0 {
                defer { MagickRelinquishMemory(blob) }
                let data = Data(bytes: blob, count: blobLength)
                if let image = NSImage(data: data) {
                    return image
                }
            }

            return nil
        }
    }

    // MARK: - Error Checking

    private func verifyStatus(_ status: MagickBooleanType, operation: String) throws {
        guard status != MagickFalse else {
            var severity: ExceptionType = UndefinedException
            if let descriptionPtr = MagickGetException(self.pointer, &severity) {
                defer { MagickRelinquishMemory(descriptionPtr) }
                let description = String(cString: descriptionPtr)
                throw MagickError.operationFailed(operation: operation, reason: description)
            }
            throw MagickError.operationFailed(operation: operation, reason: "Unknown ImageMagick error")
        }
    }
}
