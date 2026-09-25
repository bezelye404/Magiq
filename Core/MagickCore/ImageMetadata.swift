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

    public init(
        width: Int,
        height: Int,
        format: String,
        colorspace: String,
        depth: Int,
        fileSize: Int64? = nil
    ) {
        self.width = width
        self.height = height
        self.format = format.uppercased()
        self.colorspace = colorspace
        self.depth = depth
        self.fileSize = fileSize
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
}
