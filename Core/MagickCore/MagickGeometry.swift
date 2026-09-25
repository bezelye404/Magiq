//
//  MagickGeometry.swift
//  Magiq
//

import Foundation

// MARK: - MagickGeometry

public struct MagickGeometry: Equatable, Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = max(1, width)
        self.height = max(1, height)
    }

    public var cliString: String {
        return "\(self.width)x\(self.height)"
    }

    public func aspectFit(within maxBounds: MagickGeometry) -> MagickGeometry {
        let widthRatio = Double(maxBounds.width) / Double(self.width)
        let heightRatio = Double(maxBounds.height) / Double(self.height)
        let scale = min(widthRatio, heightRatio, 1.0)

        let targetWidth = max(1, Int((Double(self.width) * scale).rounded()))
        let targetHeight = max(1, Int((Double(self.height) * scale).rounded()))
        return MagickGeometry(width: targetWidth, height: targetHeight)
    }
}
