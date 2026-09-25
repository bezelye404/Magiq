//
//  MagickGeometry.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Foundation

// MARK: - MagickGeometry

/// Helper structure for calculating image dimensions and ImageMagick geometry specifications.
public struct MagickGeometry: Equatable, Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = max(1, width)
        self.height = max(1, height)
    }

    /// Generates a standard ImageMagick geometry string (e.g., "1920x1080").
    public var cliString: String {
        return "\(self.width)x\(self.height)"
    }

    /// Computes a fitted size that maintains aspect ratio within bounding limits.
    ///
    /// - Parameter maxBounds: Maximum allowed width and height.
    /// - Returns: A new geometry respecting the original aspect ratio.
    public func aspectFit(within maxBounds: MagickGeometry) -> MagickGeometry {
        let widthRatio = Double(maxBounds.width) / Double(self.width)
        let heightRatio = Double(maxBounds.height) / Double(self.height)
        let scale = min(widthRatio, heightRatio, 1.0)

        let targetWidth = max(1, Int((Double(self.width) * scale).rounded()))
        let targetHeight = max(1, Int((Double(self.height) * scale).rounded()))
        return MagickGeometry(width: targetWidth, height: targetHeight)
    }
}
