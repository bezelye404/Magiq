//
//  ImageOperation.swift
//  Magiq
//

import Foundation

// MARK: - ImageOperation Protocol

public protocol ImageOperation: Codable, Sendable {
    var id: UUID { get }
    var name: String { get }
    func apply(to wand: ImageWand) throws
    var cliArguments: [String] { get }
}

// MARK: - Concrete Operations

public struct ResizeOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Resize" }
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

public struct RotateOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Rotate" }
    public var degrees: Double

    public init(id: UUID = UUID(), degrees: Double) {
        self.id = id
        self.degrees = degrees
    }

    public func apply(to wand: ImageWand) throws {
        try wand.rotate(degrees: self.degrees)
    }

    public var cliArguments: [String] {
        return ["-rotate", "\(self.degrees)"]
    }
}

public struct CropOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Crop" }
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
        try wand.crop(x: self.x, y: self.y, width: self.width, height: self.height)
    }

    public var cliArguments: [String] {
        return ["-crop", "\(self.width)x\(self.height)+\(self.x)+\(self.y)", "+repage"]
    }
}

public struct FormatConvertOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Format & Quality" }
    public var format: String
    public var quality: Int

    public init(id: UUID = UUID(), format: String, quality: Int = 85) {
        self.id = id
        self.format = format.uppercased()
        self.quality = max(1, min(100, quality))
    }

    public func apply(to wand: ImageWand) throws {
        try wand.setFormat(self.format)
        try wand.setCompressionQuality(self.quality)
    }

    public var cliArguments: [String] {
        return ["-quality", "\(self.quality)"]
    }
}
