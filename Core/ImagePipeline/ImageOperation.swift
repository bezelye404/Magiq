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

// MARK: - Watermark & Text Annotation

public enum WatermarkPosition: String, CaseIterable, Identifiable, Codable, Sendable {
    case topLeft = "Top Left"
    case topCenter = "Top Center"
    case topRight = "Top Right"
    case center = "Center"
    case bottomLeft = "Bottom Left"
    case bottomCenter = "Bottom Center"
    case bottomRight = "Bottom Right"

    public var id: String { self.rawValue }

    public var cliGravity: String {
        switch self {
        case .topLeft: return "NorthWest"
        case .topCenter: return "North"
        case .topRight: return "NorthEast"
        case .center: return "Center"
        case .bottomLeft: return "SouthWest"
        case .bottomCenter: return "South"
        case .bottomRight: return "SouthEast"
        }
    }
}

public struct WatermarkOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Watermark" }
    public var text: String
    public var fontSize: Int
    public var opacity: Double
    public var position: WatermarkPosition
    public var color: String

    public init(
        id: UUID = UUID(),
        text: String = "",
        fontSize: Int = 28,
        opacity: Double = 0.7,
        position: WatermarkPosition = .bottomRight,
        color: String = "white"
    ) {
        self.id = id
        self.text = text
        self.fontSize = max(8, min(120, fontSize))
        self.opacity = max(0.05, min(1.0, opacity))
        self.position = position
        self.color = color
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.text.isEmpty else { return }
        try wand.annotate(
            text: self.text,
            fontSize: Double(self.fontSize),
            color: self.color,
            opacity: self.opacity,
            position: self.position
        )
    }

    public var cliArguments: [String] {
        guard !self.text.isEmpty else { return [] }
        return [
            "-gravity", self.position.cliGravity,
            "-pointsize", "\(self.fontSize)",
            "-fill", self.color,
            "-annotate", "+20+20", self.text
        ]
    }
}

// MARK: - Levels & Gamma Operation

public struct LevelsOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Levels & Gamma" }
    public var blackPoint: Double
    public var gamma: Double
    public var whitePoint: Double

    public init(
        id: UUID = UUID(),
        blackPoint: Double = 0.0,
        gamma: Double = 1.0,
        whitePoint: Double = 255.0
    ) {
        self.id = id
        self.blackPoint = max(0.0, min(255.0, blackPoint))
        self.gamma = max(0.1, min(5.0, gamma))
        self.whitePoint = max(0.0, min(255.0, whitePoint))
    }

    public var isIdentity: Bool {
        return self.blackPoint == 0.0 && abs(self.gamma - 1.0) < 0.001 && self.whitePoint == 255.0
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.level(blackPoint: self.blackPoint, gamma: self.gamma, whitePoint: self.whitePoint)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        let bpPercent = String(format: "%.1f%%", (self.blackPoint / 255.0) * 100.0)
        let wpPercent = String(format: "%.1f%%", (self.whitePoint / 255.0) * 100.0)
        let gammaStr = String(format: "%.2f", self.gamma)
        return ["-level", "\(bpPercent),\(wpPercent),\(gammaStr)"]
    }
}

// MARK: - Artistic Tone & Special Effects Operation

public struct ArtisticToneOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Tone & Special Effects" }
    public var sepia: Double
    public var negate: Bool
    public var denoise: Double

    public init(
        id: UUID = UUID(),
        sepia: Double = 0.0,
        negate: Bool = false,
        denoise: Double = 0.0
    ) {
        self.id = id
        self.sepia = max(0.0, min(100.0, sepia))
        self.negate = negate
        self.denoise = max(0.0, min(10.0, denoise))
    }

    public var isIdentity: Bool {
        return self.sepia == 0.0 && !self.negate && self.denoise == 0.0
    }

    public func apply(to wand: ImageWand) throws {
        if self.negate {
            try wand.negate()
        }
        if self.sepia > 0 {
            try wand.sepiaTone(thresholdPercent: self.sepia)
        }
        if self.denoise > 0 {
            try wand.despeckle()
        }
    }

    public var cliArguments: [String] {
        var args: [String] = []
        if self.negate {
            args.append("-negate")
        }
        if self.sepia > 0 {
            args += ["-sepia-tone", "\(Int(self.sepia))%"]
        }
        if self.denoise > 0 {
            args += ["-despeckle"]
        }
        return args
    }
}

// MARK: - Auto-Trim Operation

public struct TrimOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Auto-Trim Borders" }
    public var fuzzPercent: Double

    public init(id: UUID = UUID(), fuzzPercent: Double = 0.0) {
        self.id = id
        self.fuzzPercent = max(0.0, min(50.0, fuzzPercent))
    }

    public func apply(to wand: ImageWand) throws {
        try wand.trim(fuzzPercent: self.fuzzPercent)
    }

    public var cliArguments: [String] {
        if self.fuzzPercent > 0 {
            return ["-fuzz", "\(Int(self.fuzzPercent))%", "-trim", "+repage"]
        }
        return ["-trim", "+repage"]
    }
}

// MARK: - Colorspace Conversion Operation

public struct ColorspaceOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Color Space (\(self.colorspace))" }
    public var colorspace: String // "sRGB", "CMYK", "Gray", "Lab", "RGB"

    public init(id: UUID = UUID(), colorspace: String = "sRGB") {
        self.id = id
        self.colorspace = colorspace
    }

    public var isIdentity: Bool {
        return self.colorspace.uppercased() == "SRGB"
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.transformColorspace(to: self.colorspace)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-colorspace", self.colorspace]
    }
}

// MARK: - Bit Depth Operation

public struct BitDepthOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Bit Depth (\(self.depth)-bit)" }
    public var depth: Int // 8, 16

    public init(id: UUID = UUID(), depth: Int = 8) {
        self.id = id
        self.depth = depth
    }

    public var isIdentity: Bool {
        return self.depth == 8
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.setDepth(self.depth)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-depth", "\(self.depth)"]
    }
}

// MARK: - Palette Quantization Operation

public struct QuantizeOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Quantize (\(self.numberColors) colors)" }
    public var numberColors: Int
    public var dither: Bool

    public init(id: UUID = UUID(), numberColors: Int = 256, dither: Bool = true) {
        self.id = id
        self.numberColors = max(2, min(256, numberColors))
        self.dither = dither
    }

    public func apply(to wand: ImageWand) throws {
        guard self.numberColors > 0 else { return }
        try wand.quantize(numberColors: self.numberColors, dither: self.dither)
    }

    public var cliArguments: [String] {
        guard self.numberColors > 0 else { return [] }
        var args = ["-colors", "\(self.numberColors)"]
        if self.dither {
            args.append(contentsOf: ["-dither", "FloydSteinberg"])
        } else {
            args.append(contentsOf: ["+dither"])
        }
        return args
    }
}

// MARK: - Border Operation

public struct BorderOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Border (\(self.width)x\(self.height))" }
    public var width: Int
    public var height: Int
    public var color: String

    public init(id: UUID = UUID(), width: Int = 10, height: Int = 10, color: String = "black") {
        self.id = id
        self.width = max(0, width)
        self.height = max(0, height)
        self.color = color
    }

    public var isIdentity: Bool {
        return self.width == 0 && self.height == 0
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.addBorder(width: self.width, height: self.height, color: self.color)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-bordercolor", self.color, "-border", "\(self.width)x\(self.height)"]
    }
}

// MARK: - 3D Frame Operation

public struct FrameOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Frame (\(self.width)x\(self.height))" }
    public var width: Int
    public var height: Int
    public var innerBevel: Int
    public var outerBevel: Int
    public var color: String

    public init(
        id: UUID = UUID(),
        width: Int = 15,
        height: Int = 15,
        innerBevel: Int = 2,
        outerBevel: Int = 2,
        color: String = "#808080"
    ) {
        self.id = id
        self.width = max(0, width)
        self.height = max(0, height)
        self.innerBevel = max(0, innerBevel)
        self.outerBevel = max(0, outerBevel)
        self.color = color
    }

    public var isIdentity: Bool {
        return self.width == 0 && self.height == 0
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.addFrame(
            width: self.width,
            height: self.height,
            innerBevel: self.innerBevel,
            outerBevel: self.outerBevel,
            color: self.color
        )
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-mattecolor", self.color, "-frame", "\(self.width)x\(self.height)+\(self.innerBevel)+\(self.outerBevel)"]
    }
}

// MARK: - Oil Paint Operation (Paket C)

public struct OilPaintOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Oil Paint (\(String(format: "%.1f", self.radius)))" }
    public var radius: Double
    public var sigma: Double

    public init(id: UUID = UUID(), radius: Double = 0.0, sigma: Double = 1.0) {
        self.id = id
        self.radius = max(0.0, min(20.0, radius))
        self.sigma = max(0.1, min(10.0, sigma))
    }

    public var isIdentity: Bool {
        return self.radius == 0.0
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.oilPaint(radius: self.radius, sigma: self.sigma)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-paint", String(format: "%.1f", self.radius)]
    }
}

// MARK: - Charcoal Operation (Paket C)

public struct CharcoalOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Charcoal (\(String(format: "%.1f", self.radius)))" }
    public var radius: Double
    public var sigma: Double

    public init(id: UUID = UUID(), radius: Double = 0.0, sigma: Double = 1.0) {
        self.id = id
        self.radius = max(0.0, min(20.0, radius))
        self.sigma = max(0.1, min(10.0, sigma))
    }

    public var isIdentity: Bool {
        return self.radius == 0.0
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.charcoal(radius: self.radius, sigma: self.sigma)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-charcoal", "\(String(format: "%.1f", self.radius))x\(String(format: "%.1f", self.sigma))"]
    }
}

// MARK: - Sketch Operation (Paket C)

public struct SketchOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Sketch (\(String(format: "%.1f", self.radius)))" }
    public var radius: Double
    public var sigma: Double
    public var angle: Double

    public init(id: UUID = UUID(), radius: Double = 0.0, sigma: Double = 1.0, angle: Double = 45.0) {
        self.id = id
        self.radius = max(0.0, min(20.0, radius))
        self.sigma = max(0.1, min(10.0, sigma))
        self.angle = angle
    }

    public var isIdentity: Bool {
        return self.radius == 0.0
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.sketch(radius: self.radius, sigma: self.sigma, angle: self.angle)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-sketch", "\(String(format: "%.1f", self.radius))x\(String(format: "%.1f", self.sigma))+\(String(format: "%.0f", self.angle))"]
    }
}

// MARK: - Emboss Operation (Paket C)

public struct EmbossOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Emboss (\(String(format: "%.1f", self.radius)))" }
    public var radius: Double
    public var sigma: Double

    public init(id: UUID = UUID(), radius: Double = 0.0, sigma: Double = 1.0) {
        self.id = id
        self.radius = max(0.0, min(20.0, radius))
        self.sigma = max(0.1, min(10.0, sigma))
    }

    public var isIdentity: Bool {
        return self.radius == 0.0
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.emboss(radius: self.radius, sigma: self.sigma)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-emboss", "\(String(format: "%.1f", self.radius))x\(String(format: "%.1f", self.sigma))"]
    }
}

// MARK: - Edge Detect Operation (Paket C)

public struct EdgeDetectOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Edge Detect (\(String(format: "%.1f", self.radius)))" }
    public var radius: Double

    public init(id: UUID = UUID(), radius: Double = 0.0) {
        self.id = id
        self.radius = max(0.0, min(20.0, radius))
    }

    public var isIdentity: Bool {
        return self.radius == 0.0
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.edge(radius: self.radius)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-edge", String(format: "%.1f", self.radius)]
    }
}

// MARK: - Add Noise Operation (Paket C)

public struct AddNoiseOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Add Noise (\(self.noiseType.rawValue))" }
    public var noiseType: MagiqNoiseType
    public var attenuate: Double

    public init(id: UUID = UUID(), noiseType: MagiqNoiseType = .gaussian, attenuate: Double = 0.0) {
        self.id = id
        self.noiseType = noiseType
        self.attenuate = max(0.0, min(10.0, attenuate))
    }

    public var isIdentity: Bool {
        return self.attenuate == 0.0
    }

    public func apply(to wand: ImageWand) throws {
        guard !self.isIdentity else { return }
        try wand.addNoise(type: self.noiseType, attenuate: self.attenuate)
    }

    public var cliArguments: [String] {
        guard !self.isIdentity else { return [] }
        return ["-attenuate", String(format: "%.2f", self.attenuate), "+noise", self.noiseType.cliName]
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
    case levels(LevelsOperation)
    case artisticTone(ArtisticToneOperation)
    case trim(TrimOperation)
    case border(BorderOperation)
    case frame(FrameOperation)
    case oilPaint(OilPaintOperation)
    case charcoal(CharcoalOperation)
    case sketch(SketchOperation)
    case emboss(EmbossOperation)
    case edge(EdgeDetectOperation)
    case addNoise(AddNoiseOperation)
    case colorspace(ColorspaceOperation)
    case bitDepth(BitDepthOperation)
    case quantize(QuantizeOperation)
    case sharpenBlur(SharpenBlurOperation)
    case stripMetadata(StripMetadataOperation)
    case formatConvert(FormatConvertOperation)
    case watermark(WatermarkOperation)
    case colorGrade(ColorGradeOperation)

    public var id: UUID {
        switch self {
        case .resize(let op): return op.id
        case .rotate(let op): return op.id
        case .crop(let op): return op.id
        case .flipFlop(let op): return op.id
        case .colorAdjust(let op): return op.id
        case .autoLevel(let op): return op.id
        case .levels(let op): return op.id
        case .artisticTone(let op): return op.id
        case .trim(let op): return op.id
        case .border(let op): return op.id
        case .frame(let op): return op.id
        case .oilPaint(let op): return op.id
        case .charcoal(let op): return op.id
        case .sketch(let op): return op.id
        case .emboss(let op): return op.id
        case .edge(let op): return op.id
        case .addNoise(let op): return op.id
        case .colorspace(let op): return op.id
        case .bitDepth(let op): return op.id
        case .quantize(let op): return op.id
        case .sharpenBlur(let op): return op.id
        case .stripMetadata(let op): return op.id
        case .formatConvert(let op): return op.id
        case .watermark(let op): return op.id
        case .colorGrade(let op): return op.id
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
        case .levels(let op): return op.name
        case .artisticTone(let op): return op.name
        case .trim(let op): return op.name
        case .border(let op): return op.name
        case .frame(let op): return op.name
        case .oilPaint(let op): return op.name
        case .charcoal(let op): return op.name
        case .sketch(let op): return op.name
        case .emboss(let op): return op.name
        case .edge(let op): return op.name
        case .addNoise(let op): return op.name
        case .colorspace(let op): return op.name
        case .bitDepth(let op): return op.name
        case .quantize(let op): return op.name
        case .sharpenBlur(let op): return op.name
        case .stripMetadata(let op): return op.name
        case .formatConvert(let op): return op.name
        case .watermark(let op): return op.name
        case .colorGrade(let op): return op.name
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
        case .levels(let op): try op.apply(to: wand)
        case .artisticTone(let op): try op.apply(to: wand)
        case .trim(let op): try op.apply(to: wand)
        case .border(let op): try op.apply(to: wand)
        case .frame(let op): try op.apply(to: wand)
        case .oilPaint(let op): try op.apply(to: wand)
        case .charcoal(let op): try op.apply(to: wand)
        case .sketch(let op): try op.apply(to: wand)
        case .emboss(let op): try op.apply(to: wand)
        case .edge(let op): try op.apply(to: wand)
        case .addNoise(let op): try op.apply(to: wand)
        case .colorspace(let op): try op.apply(to: wand)
        case .bitDepth(let op): try op.apply(to: wand)
        case .quantize(let op): try op.apply(to: wand)
        case .sharpenBlur(let op): try op.apply(to: wand)
        case .stripMetadata(let op): try op.apply(to: wand)
        case .formatConvert(let op): try op.apply(to: wand)
        case .watermark(let op): try op.apply(to: wand)
        case .colorGrade(let op): try op.apply(to: wand)
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
        case .levels(let op): return op.cliArguments
        case .artisticTone(let op): return op.cliArguments
        case .trim(let op): return op.cliArguments
        case .border(let op): return op.cliArguments
        case .frame(let op): return op.cliArguments
        case .oilPaint(let op): return op.cliArguments
        case .charcoal(let op): return op.cliArguments
        case .sketch(let op): return op.cliArguments
        case .emboss(let op): return op.cliArguments
        case .edge(let op): return op.cliArguments
        case .addNoise(let op): return op.cliArguments
        case .colorspace(let op): return op.cliArguments
        case .bitDepth(let op): return op.cliArguments
        case .quantize(let op): return op.cliArguments
        case .sharpenBlur(let op): return op.cliArguments
        case .stripMetadata(let op): return op.cliArguments
        case .formatConvert(let op): return op.cliArguments
        case .watermark(let op): return op.cliArguments
        case .colorGrade(let op): return op.cliArguments
        }
    }
}
