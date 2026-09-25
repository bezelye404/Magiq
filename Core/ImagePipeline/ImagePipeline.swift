//
//  ImagePipeline.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import AppKit
import Foundation

// MARK: - ImagePipeline

/// Central pipeline routing image operations between the Linked C API and the bundled CLI.
///
/// **Hybrid Strategy Implementation (ARCHITECTURE.md):**
/// 1. **Linked Path:** Live previews and bounded thumbnails are processed directly in-memory
///    using `ImageWand` to avoid process spawning overhead and keep latency under 16ms.
/// 2. **CLI Path:** Final exports to disk use `MagickCLIExecutor` with strict argument arrays,
///    ensuring access to all ImageMagick delegates without loading full buffers into app RAM.
public final class ImagePipeline: Sendable {
    public static let shared = ImagePipeline()

    private let cliExecutor = MagickCLIExecutor.shared
    private let cache = ThumbnailCache.shared

    private init() {}

    // MARK: - Previews & Thumbnails (Linked Path)

    /// Generates or fetches a cached bounded preview image.
    ///
    /// **Linked Path Rationale:**
    /// Reads and downscales directly inside `libMagickWand` in RAM, avoiding process spawn
    /// latency during UI scrolling and interactive adjustments.
    public func generatePreview(
        from url: URL,
        boundedTo bounds: MagickGeometry = MagickGeometry(width: 800, height: 800),
        operations: [any ImageOperation] = []
    ) async throws -> NSImage {
        // Check LRU cache if no dynamic operations are pending
        if operations.isEmpty, let cached = self.cache.image(for: url, geometry: bounds) {
            return cached
        }

        return try await Task.detached(priority: .userInitiated) {
            let wand = try ImageWand()
            // Read with bounded geometry constraint to preserve RAM
            try wand.readThumbnail(from: url, maxBounds: bounds)

            // Apply operations sequentially in memory
            for op in operations {
                try op.apply(to: wand)
            }

            guard let rendered = wand.makeNSImage() else {
                throw MagickError.operationFailed(
                    operation: "makeNSImage",
                    reason: "Failed to render preview bitmap from wand"
                )
            }

            if operations.isEmpty {
                self.cache.insert(rendered, for: url, geometry: bounds)
            }

            return rendered
        }.value
    }

    // MARK: - Final Export (CLI Path)

    /// Exports an image to a destination URL by applying an array of operations.
    ///
    /// **CLI Path Rationale:**
    /// Final exports use the bundled `magick` process with argument arrays to ensure
    /// 100% format/delegate support and isolate peak export memory outside the main app process.
    public func export(
        from sourceURL: URL,
        to destinationURL: URL,
        operations: [any ImageOperation]
    ) async throws -> MagickCLIResult {
        var args = MagickCLIArguments()
        args.appendInputPath(sourceURL.path)

        for op in operations {
            for flag in op.cliArguments {
                args.append(option: flag)
            }
        }

        args.appendOutputPath(destinationURL.path)

        return try await self.cliExecutor.execute(arguments: args.rawArguments)
    }
}
