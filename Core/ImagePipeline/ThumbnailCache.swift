//
//  ThumbnailCache.swift
//  Magiq
//

import AppKit
import Foundation

// MARK: - ThumbnailCache

public final class ThumbnailCache: @unchecked Sendable {
    public static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()

    public init(maxMemoryBytes: Int = 100 * 1024 * 1024) {
        self.cache.totalCostLimit = maxMemoryBytes
        self.cache.countLimit = 500
    }

    public func image(for url: URL, geometry: MagickGeometry) -> NSImage? {
        let key = self.cacheKey(for: url, geometry: geometry)
        return self.cache.object(forKey: key as NSString)
    }

    public func insert(_ image: NSImage, for url: URL, geometry: MagickGeometry) {
        let key = self.cacheKey(for: url, geometry: geometry)
        let cost = geometry.width * geometry.height * 4
        self.cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    public func removeAll() {
        self.cache.removeAllObjects()
    }

    private func cacheKey(for url: URL, geometry: MagickGeometry) -> String {
        return "\(url.path)#\(geometry.cliString)"
    }
}
