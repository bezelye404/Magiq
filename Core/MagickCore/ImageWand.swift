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

    public func clone() throws -> ImageWand {
        guard let clonedPtr = CloneMagickWand(self.pointer) else {
            throw MagickError.wandAllocationFailed
        }
        return ImageWand(pointer: clonedPtr)
    }

    // MARK: - NSImage Interop

    /// Renders the current buffer directly to an NSImage for SwiftUI live previews.
    public func makeNSImage() -> NSImage? {
        guard self.width > 0, self.height > 0 else { return nil }

        guard let tempWand = CloneMagickWand(self.pointer) else { return nil }
        defer { DestroyMagickWand(tempWand) }

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
