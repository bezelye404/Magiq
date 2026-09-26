//
//  UserSettings.swift
//  Magiq
//

import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - UserSettings

@MainActor
public final class UserSettings: ObservableObject {
    public static let shared = UserSettings()

    // MARK: - General Preferences
    @AppStorage("defaultFormat") public var defaultFormat: String = "WEBP"
    @AppStorage("defaultQuality") public var defaultQuality: Int = 85
    @AppStorage("preserveMetadata") public var preserveMetadata: Bool = true
    @AppStorage("autoFitOnOpen") public var autoFitOnOpen: Bool = true

    // MARK: - Performance & Memory
    @AppStorage("workerCount") public var workerCount: Int = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)
    @AppStorage("maxCacheMemoryMB") public var maxCacheMemoryMB: Int = 100

    // MARK: - Canvas & Appearance
    @AppStorage("canvasBackground") public var canvasBackground: String = "Neutral Dark"
    @AppStorage("zoomSensitivity") public var zoomSensitivity: Double = 1.25

    // MARK: - Privacy Preferences
    @AppStorage("stripMetadataByDefault") public var stripMetadataByDefault: Bool = false
    @AppStorage("clearRecentFilesOnExit") public var clearRecentFilesOnExit: Bool = true

    public init() {}

    public func clearThumbnailCache() {
        ThumbnailCache.shared.removeAll()
    }

    /// Revokes and flushes all security-scoped bookmarks and stored sandbox permissions.
    public func resetSandboxPermissions() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            if key.contains("Bookmark") || key.contains("SecurityScoped") || key.contains("FolderAccess") || key.contains("recent") || key.contains("Recent") {
                defaults.removeObject(forKey: key)
            }
        }
        NSDocumentController.shared.clearRecentDocuments(nil)
    }

    /// Resets all privacy-related settings, clears stored bookmarks, and flushes thumbnail/render cache.
    public func resetPrivacySettings() {
        self.clearThumbnailCache()
        self.preserveMetadata = true
        self.stripMetadataByDefault = false
        self.clearRecentFilesOnExit = true
        self.resetSandboxPermissions()
    }
}
