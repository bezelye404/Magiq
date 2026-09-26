//
//  ImageMetadata.swift
//  Magiq
//

import Foundation

// MARK: - ImageMetadata

/// Encapsulates lightweight metadata read from an image header without full buffer decode.
public struct ImageMetadata: Sendable, Equatable, Codable {
    public let width: Int
    public let height: Int
    public let format: String
    public let colorspace: String
    public let depth: Int
    public let fileSize: Int64?
    public let properties: [String: String]

    public init(
        width: Int,
        height: Int,
        format: String,
        colorspace: String,
        depth: Int,
        fileSize: Int64? = nil,
        properties: [String: String] = [:]
    ) {
        self.width = width
        self.height = height
        self.format = format.uppercased()
        self.colorspace = colorspace
        self.depth = depth
        self.fileSize = fileSize
        self.properties = properties
    }

    public var dimensionsString: String {
        "\(self.width) × \(self.height) px"
    }

    public var aspectRatio: Double {
        guard self.height > 0 else { return 1.0 }
        return Double(self.width) / Double(self.height)
    }

    public var fileSizeFormatted: String? {
        guard let size = self.fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    // MARK: - Photography & EXIF Helpers

    public var cameraModel: String? {
        if let model = self.properties["exif:Model"] {
            if let make = self.properties["exif:Make"], !model.contains(make) {
                return "\(make) \(model)"
            }
            return model
        }
        return self.properties["exif:Make"]
    }

    public var lensModel: String? {
        self.properties["exif:LensModel"]
    }

    public var aperture: String? {
        guard let fVal = self.properties["exif:FNumber"] else { return nil }
        if fVal.contains("/") {
            let parts = fVal.split(separator: "/")
            if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]), den > 0 {
                return String(format: "ƒ/%.1f", num / den)
            }
        }
        if let d = Double(fVal) {
            return String(format: "ƒ/%.1f", d)
        }
        return "ƒ/\(fVal)"
    }

    public var shutterSpeed: String? {
        guard let speed = self.properties["exif:ExposureTime"] else { return nil }
        if speed.contains("/") {
            return "\(speed)s"
        }
        if let d = Double(speed), d > 0 {
            if d < 1.0 {
                let denom = Int(round(1.0 / d))
                return "1/\(denom)s"
            } else {
                return String(format: "%.1fs", d)
            }
        }
        return "\(speed)s"
    }

    public var iso: String? {
        if let val = self.properties["exif:PhotographicSensitivity"] ?? self.properties["exif:ISOSpeedRatings"] {
            return "ISO \(val)"
        }
        return nil
    }

    public var focalLength: String? {
        guard let fl = self.properties["exif:FocalLength"] else { return nil }
        if fl.contains("/") {
            let parts = fl.split(separator: "/")
            if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]), den > 0 {
                return "\(Int(round(num / den)))mm"
            }
        }
        if let d = Double(fl) {
            return "\(Int(round(d)))mm"
        }
        return "\(fl)mm"
    }

    public var hasGPS: Bool {
        self.properties.keys.contains { $0.lowercased().contains("gps") }
    }

    public var hasCameraData: Bool {
        self.cameraModel != nil || self.aperture != nil || self.iso != nil || self.shutterSpeed != nil
    }

    public var formattedSummary: String {
        var lines: [String] = []
        lines.append("Format: \(self.format)")
        lines.append("Dimensions: \(self.dimensionsString)")
        lines.append("Color Space: \(self.colorspace)")
        lines.append("Bit Depth: \(self.depth)-bit")
        if let size = self.fileSizeFormatted {
            lines.append("File Size: \(size)")
        }
        if let cam = self.cameraModel {
            lines.append("Camera: \(cam)")
        }
        if let lens = self.lensModel {
            lines.append("Lens: \(lens)")
        }
        var exposureBits: [String] = []
        if let ap = self.aperture { exposureBits.append(ap) }
        if let ss = self.shutterSpeed { exposureBits.append(ss) }
        if let isoVal = self.iso { exposureBits.append(isoVal) }
        if let fl = self.focalLength { exposureBits.append(fl) }
        if !exposureBits.isEmpty {
            lines.append("Settings: " + exposureBits.joined(separator: " • "))
        }
        return lines.joined(separator: "\n")
    }
}
