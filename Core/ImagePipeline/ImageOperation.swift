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

public struct FlipFlopOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Flip / Flop" }
    public var horizontal: Bool
    public var vertical: Bool

    public init(id: UUID = UUID(), horizontal: Bool = false, vertical: Bool = false) {
        self.id = id
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public func apply(to wand: ImageWand) throws {
        if self.horizontal {
            try wand.flop()
        }
        if self.vertical {
            try wand.flip()
        }
    }

    public var cliArguments: [String] {
        var args: [String] = []
        if self.horizontal { args.append("-flop") }
        if self.vertical { args.append("-flip") }
        return args
    }
}

public struct ColorAdjustOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Color Adjustments" }
    public var brightness: Double
    public var contrast: Double
    public var saturation: Double

    public init(
        id: UUID = UUID(),
        brightness: Double = 0.0,
        contrast: Double = 0.0,
        saturation: Double = 0.0
    ) {
        self.id = id
        self.brightness = max(-100.0, min(100.0, brightness))
        self.contrast = max(-100.0, min(100.0, contrast))
        self.saturation = max(-100.0, min(100.0, saturation))
    }

    public func apply(to wand: ImageWand) throws {
        if self.brightness != 0.0 || self.contrast != 0.0 {
            try wand.brightnessContrast(brightness: self.brightness, contrast: self.contrast)
        }
        if self.saturation != 0.0 {
            let satPercent = max(0.0, 100.0 + self.saturation)
            try wand.modulate(brightness: 100.0, saturation: satPercent, hue: 100.0)
        }
    }

    public var cliArguments: [String] {
        var args: [String] = []
        if self.brightness != 0.0 || self.contrast != 0.0 {
            args.append(contentsOf: ["-brightness-contrast", "\(Int(self.brightness))x\(Int(self.contrast))"])
        }
        if self.saturation != 0.0 {
            let satPercent = Int(max(0.0, 100.0 + self.saturation))
            args.append(contentsOf: ["-modulate", "100,\(satPercent),100"])
        }
        return args
    }
}

public struct AutoLevelOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Auto Level" }
    public var enabled: Bool

    public init(id: UUID = UUID(), enabled: Bool = true) {
        self.id = id
        self.enabled = enabled
    }

    public func apply(to wand: ImageWand) throws {
        guard self.enabled else { return }
        try wand.autoLevel()
    }

    public var cliArguments: [String] {
        return self.enabled ? ["-auto-level"] : []
    }
}

public struct SharpenBlurOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Sharpen & Blur" }
    public var sharpen: Double
    public var blur: Double

    public init(id: UUID = UUID(), sharpen: Double = 0.0, blur: Double = 0.0) {
        self.id = id
        self.sharpen = max(0.0, min(10.0, sharpen))
        self.blur = max(0.0, min(20.0, blur))
    }

    public func apply(to wand: ImageWand) throws {
        if self.sharpen > 0.0 {
            try wand.sharpen(radius: 0.0, sigma: self.sharpen)
        }
        if self.blur > 0.0 {
            try wand.blur(radius: 0.0, sigma: self.blur)
        }
    }

    public var cliArguments: [String] {
        var args: [String] = []
        if self.sharpen > 0.0 {
            args.append(contentsOf: ["-sharpen", "0x\(String(format: "%.1f", self.sharpen))"])
        }
        if self.blur > 0.0 {
            args.append(contentsOf: ["-blur", "0x\(String(format: "%.1f", self.blur))"])
        }
        return args
    }
}

public struct StripMetadataOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Strip Metadata (Privacy)" }
    public var enabled: Bool

    public init(id: UUID = UUID(), enabled: Bool = true) {
        self.id = id
        self.enabled = enabled
    }

    public func apply(to wand: ImageWand) throws {
        guard self.enabled else { return }
        try wand.strip()
    }

    public var cliArguments: [String] {
        return self.enabled ? ["-strip"] : []
    }
}

// MARK: - PipelineOperation Enum (For Presets & History Serialization)

public enum PipelineOperation: ImageOperation, Equatable {
    case resize(ResizeOperation)
    case rotate(RotateOperation)
    case crop(CropOperation)
    case flipFlop(FlipFlopOperation)
    case colorAdjust(ColorAdjustOperation)
    case autoLevel(AutoLevelOperation)
    case sharpenBlur(SharpenBlurOperation)
    case stripMetadata(StripMetadataOperation)
    case formatConvert(FormatConvertOperation)

    public var id: UUID {
        switch self {
        case .resize(let op): return op.id
        case .rotate(let op): return op.id
        case .crop(let op): return op.id
        case .flipFlop(let op): return op.id
        case .colorAdjust(let op): return op.id
        case .autoLevel(let op): return op.id
        case .sharpenBlur(let op): return op.id
        case .stripMetadata(let op): return op.id
        case .formatConvert(let op): return op.id
        }
    }

    public var name: String {
        switch self {
        case .resize(let op): return op.name
        case .rotate(let op): return op.name
        case .crop(let op): return op.name
        case .flipFlop(let op): return op.name
        case .colorAdjust(let op): return op.name
        case .autoLevel(let op): return op.name
        case .sharpenBlur(let op): return op.name
        case .stripMetadata(let op): return op.name
        case .formatConvert(let op): return op.name
        }
    }

    public func apply(to wand: ImageWand) throws {
        switch self {
        case .resize(let op): try op.apply(to: wand)
        case .rotate(let op): try op.apply(to: wand)
        case .crop(let op): try op.apply(to: wand)
        case .flipFlop(let op): try op.apply(to: wand)
        case .colorAdjust(let op): try op.apply(to: wand)
        case .autoLevel(let op): try op.apply(to: wand)
        case .sharpenBlur(let op): try op.apply(to: wand)
        case .stripMetadata(let op): try op.apply(to: wand)
        case .formatConvert(let op): try op.apply(to: wand)
        }
    }

    public var cliArguments: [String] {
        switch self {
        case .resize(let op): return op.cliArguments
        case .rotate(let op): return op.cliArguments
        case .crop(let op): return op.cliArguments
        case .flipFlop(let op): return op.cliArguments
        case .colorAdjust(let op): return op.cliArguments
        case .autoLevel(let op): return op.cliArguments
        case .sharpenBlur(let op): return op.cliArguments
        case .stripMetadata(let op): return op.cliArguments
        case .formatConvert(let op): return op.cliArguments
        }
    }
}
