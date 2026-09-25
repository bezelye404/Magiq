//
//  ImageWand.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import AppKit
import Foundation

// MARK: - ImageWand

/// RAII wrapper around ImageMagick's `MagickWand*` C pointer.
///
/// **Architecture Justification (Linked Path):**
/// This class directly links to `libMagickWand` for low-latency operations invoked repeatedly
/// during user sessions (thumbnails, live parameter previews, interactive canvas rendering,
/// and batch step execution). This avoids process-spawning overhead and keeps memory bounded.
public final class ImageWand: Identifiable {
    public let id = UUID()
    public let pointer: OpaquePointer

    // MARK: - Initialization & Lifecycle

    /// Initializes a new, empty ImageWand.
    public init() throws {
        WandSession.shared.ensureInitialized()
        guard let ptr = NewMagickWand() else {
            throw MagickError.wandAllocationFailed
        }
        self.pointer = ptr
    }

    /// Internal initializer for cloned or child wands.
    private init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        // Enforces AGENTS.md rule #4 (Deterministic RAM discipline)
        DestroyMagickWand(self.pointer)
    }

    // MARK: - Properties

    /// The current pixel width of the active image.
    public var width: Int {
        return MagickGetImageWidth(self.pointer)
    }

    /// The current pixel height of the active image.
    public var height: Int {
        return MagickGetImageHeight(self.pointer)
    }

    /// The current image format (e.g., "PNG", "JPEG", "WEBP").
    public var format: String? {
        guard let formatCString = MagickGetImageFormat(self.pointer) else { return nil }
        defer { MagickRelinquishMemory(formatCString) }
        return String(cString: formatCString)
    }

    /// Returns the current dimensions as a geometry object.
    public var geometry: MagickGeometry {
        return MagickGeometry(width: self.width, height: self.height)
    }

    // MARK: - Reading & Writing

    /// Reads an image from the specified file URL.
    ///
    /// - Parameter url: The file URL of the image to read.
    public func read(from url: URL) throws {
        let status = MagickReadImage(self.pointer, url.path)
        try self.verifyStatus(status, operation: "MagickReadImage (\(url.lastPathComponent))")
    }

    /// Reads a thumbnail of an image, setting bounded read geometry to prevent large allocations.
    ///
    /// **Linked Path Rationale:**
    /// Reads and downscales directly inside memory without spawning an external process,
    /// enabling fast thumbnail generation for batch lists and gallery views.
    public func readThumbnail(from url: URL, maxBounds: MagickGeometry) throws {
        // Set geometry hint to optimize decode allocation where decoder supports it
        let geomString = "\(maxBounds.width)x\(maxBounds.height)"
        MagickSetSize(self.pointer, size_t(maxBounds.width), size_t(maxBounds.height))

        let status = MagickReadImage(self.pointer, url.path)
        try self.verifyStatus(status, operation: "MagickReadImage thumbnail")

        // Further downscale using Lanczos filter if read exceeded target bounds
        let currentGeom = self.geometry
        if currentGeom.width > maxBounds.width || currentGeom.height > maxBounds.height {
            let fitted = currentGeom.aspectFit(within: maxBounds)
            try self.resize(to: fitted)
        }
    }

    /// Writes the image to the specified destination URL.
    public func write(to url: URL) throws {
        let status = MagickWriteImage(self.pointer, url.path)
        try self.verifyStatus(status, operation: "MagickWriteImage (\(url.lastPathComponent))")
    }

    // MARK: - Transformations (Linked Path Hot-Path)

    /// Resizes the image to the specified target dimensions.
    ///
    /// **Linked Path Rationale:**
    /// Called interactively during canvas zooming, inspector adjustments, and batch processing.
    public func resize(to geometry: MagickGeometry) throws {
        let status = MagickResizeImage(
            self.pointer,
            size_t(geometry.width),
            size_t(geometry.height),
            LanczosFilter
        )
        try self.verifyStatus(status, operation: "MagickResizeImage")
    }

    /// Rotates the image by the specified angle in degrees.
    public func rotate(degrees: Double, background: String = "none") throws {
        let pixelWand = try PixelWandWrapper(color: background)
        let status = MagickRotateImage(self.pointer, pixelWand.pointer, degrees)
        try self.verifyStatus(status, operation: "MagickRotateImage")
    }

    /// Crops the image to the given rectangle.
    public func crop(x: Int, y: Int, width: Int, height: Int) throws {
        let status = MagickCropImage(
            self.pointer,
            size_t(width),
            size_t(height),
            ssize_t(x),
            ssize_t(y)
        )
        try self.verifyStatus(status, operation: "MagickCropImage")
        // Reset page geometry so offset is normalized
        MagickResetImagePage(self.pointer, "0x0+0+0")
    }

    /// Sets the target output format (e.g. "WEBP", "PNG", "JPEG").
    public func setFormat(_ format: String) throws {
        let status = MagickSetImageFormat(self.pointer, format.uppercased())
        try self.verifyStatus(status, operation: "MagickSetImageFormat (\(format))")
    }

    /// Sets the compression quality (1 to 100).
    public func setCompressionQuality(_ quality: Int) throws {
        let clampedQuality = size_t(max(1, min(100, quality)))
        let status = MagickSetImageCompressionQuality(self.pointer, clampedQuality)
        try self.verifyStatus(status, operation: "MagickSetImageCompressionQuality (\(quality))")
    }

    // MARK: - Rendering & NSImage Interop

    /// Clones this image wand.
    public func clone() throws -> ImageWand {
        guard let clonedPtr = CloneMagickWand(self.pointer) else {
            throw MagickError.wandAllocationFailed
        }
        return ImageWand(pointer: clonedPtr)
    }

    /// Exports the current image to a native `NSImage` for live SwiftUI rendering.
    ///
    /// **Linked Path Rationale:**
    /// Encodes the current memory buffer into PNG blob in RAM, feeding SwiftUI views directly
    /// without touching disk I/O.
    public func makeNSImage() -> NSImage? {
        guard self.width > 0, self.height > 0 else { return nil }

        // Clone to avoid modifying the working wand's format
        guard let tempWand = CloneMagickWand(self.pointer) else { return nil }
        defer { DestroyMagickWand(tempWand) }

        // Set PNG format for lossless display rendering
        MagickSetImageFormat(tempWand, "PNG")

        var blobLength: size_t = 0
        guard let blob = MagickGetImageBlob(tempWand, &blobLength), blobLength > 0 else {
            return nil
        }
        defer { MagickRelinquishMemory(blob) }

        let data = Data(bytes: blob, count: blobLength)
        return NSImage(data: data)
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
