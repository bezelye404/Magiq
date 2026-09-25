//
//  Histogram.swift
//  Magiq
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - HistogramData

/// Stores normalized 256-bin frequency distributions for image color channels.
public struct HistogramData: Sendable, Equatable {
    public let luminance: [Float]
    public let red: [Float]
    public let green: [Float]
    public let blue: [Float]

    public let shadowClipping: Float
    public let highlightClipping: Float

    public init(
        luminance: [Float],
        red: [Float],
        green: [Float],
        blue: [Float],
        shadowClipping: Float = 0.0,
        highlightClipping: Float = 0.0
    ) {
        self.luminance = luminance
        self.red = red
        self.green = green
        self.blue = blue
        self.shadowClipping = shadowClipping
        self.highlightClipping = highlightClipping
    }

    /// Fast, memory-disciplined histogram extraction from an NSImage.
    /// Operates inside an autoreleasepool with direct raw pixel byte scanning.
    public static func calculate(from image: NSImage) -> HistogramData? {
        return autoreleasepool {
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return nil
            }

            let width = min(cgImage.width, 800)
            let height = min(cgImage.height, 800)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            let bitsPerComponent = 8

            var rawBytes = [UInt8](repeating: 0, count: bytesPerRow * height)

            guard let context = CGContext(
                data: &rawBytes,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ) else {
                return nil
            }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            var lumaBins = [Int](repeating: 0, count: 256)
            var redBins = [Int](repeating: 0, count: 256)
            var greenBins = [Int](repeating: 0, count: 256)
            var blueBins = [Int](repeating: 0, count: 256)

            let totalPixels = width * height
            var shadowCount = 0
            var highlightCount = 0

            for i in stride(from: 0, to: rawBytes.count, by: bytesPerPixel) {
                let r = Int(rawBytes[i])
                let g = Int(rawBytes[i + 1])
                let b = Int(rawBytes[i + 2])

                // Standard ITU-R BT.601 luma formula
                let luma = Int(0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                let clampedLuma = max(0, min(255, luma))

                redBins[r] += 1
                greenBins[g] += 1
                blueBins[b] += 1
                lumaBins[clampedLuma] += 1

                if clampedLuma == 0 { shadowCount += 1 }
                if clampedLuma >= 254 { highlightCount += 1 }
            }

            // Find peak for normalization
            let maxCount = max(1, lumaBins.max() ?? 1)
            let maxRed = max(1, redBins.max() ?? 1)
            let maxGreen = max(1, greenBins.max() ?? 1)
            let maxBlue = max(1, blueBins.max() ?? 1)

            let normLuma = lumaBins.map { Float($0) / Float(maxCount) }
            let normRed = redBins.map { Float($0) / Float(maxRed) }
            let normGreen = greenBins.map { Float($0) / Float(maxGreen) }
            let normBlue = blueBins.map { Float($0) / Float(maxBlue) }

            let shadowClip = Float(shadowCount) / Float(totalPixels)
            let highlightClip = Float(highlightCount) / Float(totalPixels)

            return HistogramData(
                luminance: normLuma,
                red: normRed,
                green: normGreen,
                blue: normBlue,
                shadowClipping: shadowClip,
                highlightClipping: highlightClip
            )
        }
    }
}
