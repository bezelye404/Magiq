//
//  ThumbnailCache.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import AppKit
import Foundation

// MARK: - ThumbnailCache

/// Bounded memory cache for image previews and thumbnails.
///
/// **RAM Discipline (AGENTS.md rule #4):**
/// Prevents unbounded memory growth during large batch processing or gallery browsing.
/// Enforces an explicit byte budget (default: 100 MB).
public final class ThumbnailCache: @unchecked Sendable {
    public static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()

    /// Initializes cache with an explicit memory ceiling.
    ///
    /// - Parameter maxMemoryBytes: Byte budget (default: 100 MB).
    public init(maxMemoryBytes: Int = 100 * 1024 * 1024) {
        self.cache.totalCostLimit = maxMemoryBytes
        self.cache.countLimit = 500
    }

    /// Retrieves a cached preview image for a URL and geometry key.
    public func image(for url: URL, geometry: MagickGeometry) -> NSImage? {
        let key = self.cacheKey(for: url, geometry: geometry)
        return self.cache.object(forKey: key as NSString)
    }

    /// Stores a rendered preview image in the bounded cache.
    public func insert(_ image: NSImage, for url: URL, geometry: MagickGeometry) {
        let key = self.cacheKey(for: url, geometry: geometry)
        // Approximate cost in bytes: width * height * 4 (RGBA)
        let cost = geometry.width * geometry.height * 4
        self.cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    /// Clears all entries from the cache.
    public func removeAll() {
        self.cache.removeAllObjects()
    }

    private func cacheKey(for url: URL, geometry: MagickGeometry) -> String {
        return "\(url.path)#\(geometry.cliString)"
    }
}
