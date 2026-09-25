//
//  SecurityScopedURL.swift
//  Magiq
//

import Foundation

// MARK: - SecurityScopedURL

public final class SecurityScopedURL {
    public let url: URL
    private var isAccessing: Bool = false

    public init(url: URL) {
        self.url = url
        self.isAccessing = url.startAccessingSecurityScopedResource()
    }

    // MARK: - Bookmark Management

    public static func createBookmark(for url: URL) throws -> Data {
        return try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    public static func resolveBookmark(data: Data) throws -> URL {
        var isStale = false
        let resolvedURL = try URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return resolvedURL
    }

    deinit {
        if self.isAccessing {
            self.url.stopAccessingSecurityScopedResource()
        }
    }
}
