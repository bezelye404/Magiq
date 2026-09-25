//
//  ImagePipeline.swift
//  Magiq
//

import AppKit
import Foundation

// MARK: - ImagePipeline

/// Central pipeline routing image operations between the Linked C API and the bundled CLI.
///
/// **Hybrid Strategy Implementation (ARCHITECTURE.md):**
/// 1. **Linked Path:** Live previews and bounded thumbnails are processed directly in-memory
///    using `ImageWand` to avoid process spawning overhead and keep latency low.
/// 2. **CLI Path:** Final exports to disk use `MagickCLIExecutor` with strict argument arrays,
///    ensuring access to all ImageMagick delegates without loading full buffers into app RAM.
public final class ImagePipeline: Sendable {
    public static let shared = ImagePipeline()

    private let cliExecutor = MagickCLIExecutor.shared
    private let cache = ThumbnailCache.shared

    private init() {}

    // MARK: - Previews & Thumbnails (Linked Path)

    public func generatePreview(
        from url: URL,
        boundedTo bounds: MagickGeometry = MagickGeometry(width: 800, height: 800),
        operations: [any ImageOperation] = []
    ) async throws -> NSImage {
        if operations.isEmpty, let cached = self.cache.image(for: url, geometry: bounds) {
            return cached
        }

        return try await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()

            return try autoreleasepool {
                let wand = try ImageWand()
                try wand.readThumbnail(from: url, maxBounds: bounds)

                for op in operations {
                    try Task.checkCancellation()
                    try op.apply(to: wand)
                }

                try Task.checkCancellation()
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
            }
        }.value
    }

    // MARK: - Export (CLI Path)

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
