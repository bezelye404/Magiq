//
//  SecurityScopedURL.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Foundation

// MARK: - SecurityScopedURL

/// Manages the access lifecycle of security-scoped URLs and persistent bookmark data.
///
/// **App Sandbox Compliance (AGENTS.md rule #3):**
/// macOS App Sandbox requires access to user-selected folders and files to be negotiated
/// through security-scoped bookmarks. This class provides an RAII scope to guarantee
/// `stopAccessingSecurityScopedResource()` is called deterministically.
public final class SecurityScopedURL {
    public let url: URL
    private var isAccessing: Bool = false

    public init(url: URL) {
        self.url = url
        self.isAccessing = url.startAccessingSecurityScopedResource()
    }

    /// Creates persistent bookmark data for the given URL.
    public static func createBookmark(for url: URL) throws -> Data {
        return try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    /// Resolves persistent bookmark data back into a usable URL.
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
