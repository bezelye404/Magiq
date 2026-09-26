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
        self.cache.countLimit = 300

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.removeAll()
        }
    }

    public func updateCostLimit(megabytes: Int) {
        self.cache.totalCostLimit = max(10, megabytes) * 1024 * 1024
    }

    public func image(for url: URL, pageIndex: Int? = nil, geometry: MagickGeometry) -> NSImage? {
        let key = self.cacheKey(for: url, pageIndex: pageIndex, geometry: geometry)
        return self.cache.object(forKey: key as NSString)
    }

    public func insert(_ image: NSImage, for url: URL, pageIndex: Int? = nil, geometry: MagickGeometry) {
        let key = self.cacheKey(for: url, pageIndex: pageIndex, geometry: geometry)
        let cost = geometry.width * geometry.height * 4
        self.cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    public func removeAll() {
        self.cache.removeAllObjects()
    }

    private func cacheKey(for url: URL, pageIndex: Int?, geometry: MagickGeometry) -> String {
        let pageSuffix = pageIndex.map { "[\($0)]" } ?? ""
        return "\(url.path)\(pageSuffix)#\(geometry.cliString)"
    }
}
