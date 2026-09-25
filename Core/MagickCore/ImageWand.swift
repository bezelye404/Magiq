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
            depth: self.depth
        )
    }

    /// Reads image metadata with zero full-buffer decode using MagickPingImage.
    public static func pingMetadata(from url: URL) throws -> ImageMetadata {
        let wand = try ImageWand()
        let status = MagickPingImage(wand.pointer, url.path)
        try wand.verifyStatus(status, operation: "MagickPingImage (\(url.lastPathComponent))")

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value

        return ImageMetadata(
            width: wand.width,
            height: wand.height,
            format: wand.format ?? url.pathExtension.uppercased(),
            colorspace: wand.colorspace,
            depth: wand.depth,
            fileSize: fileSize
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
    public func readThumbnail(from url: URL, maxBounds: MagickGeometry) throws {
        MagickSetSize(self.pointer, size_t(maxBounds.width), size_t(maxBounds.height))

        let status = MagickReadImage(self.pointer, url.path)
        try self.verifyStatus(status, operation: "MagickReadImage thumbnail")

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
