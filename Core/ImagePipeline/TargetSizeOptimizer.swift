//
//  TargetSizeOptimizer.swift
//  Magiq
//

import Foundation

// MARK: - OptimizationResult

public struct OptimizationResult: Sendable, Equatable {
    public let optimalQuality: Int
    public let estimatedSizeBytes: Int
    public let targetSizeBytes: Int
    public let iterationsUsed: Int

    public var estimatedSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(self.estimatedSizeBytes), countStyle: .file)
    }

    public var targetSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(self.targetSizeBytes), countStyle: .file)
    }
}

// MARK: - TargetSizeOptimizer

/// Binary search optimizer that finds the highest visual quality satisfying a target file size budget.
public enum TargetSizeOptimizer {

    /// Finds the optimal compression quality using at most `maxIterations` in-memory test encodings.
    public static func findOptimalQuality(
        for url: URL,
        format: String,
        targetSizeBytes: Int,
        operations: [any ImageOperation] = [],
        maxIterations: Int = 5
    ) async throws -> OptimizationResult {
        return try await Task.detached(priority: .userInitiated) {
            var low = 15
            var high = 95
            var bestQuality = 80
            var bestSize = 0
            var iterations = 0

            while low <= high && iterations < maxIterations {
                iterations += 1
                let mid = (low + high) / 2

                let size = try autoreleasepool { () -> Int in
                    let wand = try ImageWand()
                    try wand.read(from: url)

                    for op in operations {
                        try op.apply(to: wand)
                    }

                    try wand.setFormat(format)
                    try wand.setCompressionQuality(mid)

                    var blobLength: size_t = 0
                    if let blob = MagickGetImageBlob(wand.pointer, &blobLength), blobLength > 0 {
                        defer { MagickRelinquishMemory(blob) }
                        return Int(blobLength)
                    }
                    return 0
                }

                if size <= targetSizeBytes {
                    bestQuality = mid
                    bestSize = size
                    low = mid + 1 // Try higher quality
                } else {
                    high = mid - 1 // Reduce quality
                }
            }

            return OptimizationResult(
                optimalQuality: bestQuality,
                estimatedSizeBytes: bestSize,
                targetSizeBytes: targetSizeBytes,
                iterationsUsed: iterations
            )
        }.value
    }
}
