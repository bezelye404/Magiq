//
//  ImageOperation.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Foundation

// MARK: - ImageOperation Protocol

/// Defines an operation that can be executed either via the Linked Path (`ImageWand`) or CLI Path.
public protocol ImageOperation: Codable, Sendable {
    var id: UUID { get }
    var name: String { get }

    /// Applies this operation directly in memory using the linked `ImageWand` (Linked Path).
    func apply(to wand: ImageWand) throws

    /// Generates CLI arguments representing this operation (CLI Path).
    var cliArguments: [String] { get }
}

// MARK: - Concrete Operations

/// Resizes an image to specified dimensions.
public struct ResizeOperation: ImageOperation, Equatable {
    public let id: UUID
    public let name = "Resize"
    public var width: Int
    public var height: Int
    public var maintainAspectRatio: Bool

    public init(id: UUID = UUID(), width: Int, height: Int, maintainAspectRatio: Bool = true) {
        self.id = id
        self.width = max(1, width)
        self.height = max(1, height)
        self.maintainAspectRatio = maintainAspectRatio
    }

    public func apply(to wand: ImageWand) throws {
        // Linked path: fast in-memory Lanczos downscale
        let targetGeom: MagickGeometry
        if self.maintainAspectRatio {
            targetGeom = wand.geometry.aspectFit(within: MagickGeometry(width: self.width, height: self.height))
        } else {
            targetGeom = MagickGeometry(width: self.width, height: self.height)
        }
        try wand.resize(to: targetGeom)
    }

    public var cliArguments: [String] {
        if self.maintainAspectRatio {
            return ["-resize", "\(self.width)x\(self.height)"]
        } else {
            return ["-resize", "\(self.width)x\(self.height)!"]
        }
    }
}

/// Rotates an image by a degree angle.
public struct RotateOperation: ImageOperation, Equatable {
    public let id: UUID
    public let name = "Rotate"
    public var degrees: Double

    public init(id: UUID = UUID(), degrees: Double) {
        self.id = id
        self.degrees = degrees
    }

    public func apply(to wand: ImageWand) throws {
        // Linked path: in-memory rotation
        try wand.rotate(degrees: self.degrees)
    }

    public var cliArguments: [String] {
        return ["-rotate", "\(self.degrees)"]
    }
}

/// Crops an image to a bounding box.
public struct CropOperation: ImageOperation, Equatable {
    public let id: UUID
    public let name = "Crop"
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int

    public init(id: UUID = UUID(), x: Int, y: Int, width: Int, height: Int) {
        self.id = id
        self.x = max(0, x)
        self.y = max(0, y)
        self.width = max(1, width)
        self.height = max(1, height)
    }

    public func apply(to wand: ImageWand) throws {
        // Linked path: in-memory crop
        try wand.crop(x: self.x, y: self.y, width: self.width, height: self.height)
    }

    public var cliArguments: [String] {
        return ["-crop", "\(self.width)x\(self.height)+\(self.x)+\(self.y)", "+repage"]
    }
}

/// Converts the output format and compression quality.
public struct FormatConvertOperation: ImageOperation, Equatable {
    public let id: UUID
    public let name = "Format & Quality"
    public var format: String
    public var quality: Int

    public init(id: UUID = UUID(), format: String, quality: Int = 85) {
        self.id = id
        self.format = format.uppercased()
        self.quality = max(1, min(100, quality))
    }

    public func apply(to wand: ImageWand) throws {
        // Linked path: update wand format and quality settings
        try wand.setFormat(self.format)
        try wand.setCompressionQuality(self.quality)
    }

    public var cliArguments: [String] {
        return ["-quality", "\(self.quality)"]
    }
}
