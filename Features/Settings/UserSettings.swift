//
//  UserSettings.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Combine
import Foundation
import SwiftUI

// MARK: - UserSettings

/// Manages local user preferences, personalization, and runtime limits.
///
/// Backed strictly by local `UserDefaults` — zero telemetry and zero network synchronization.
@MainActor
public final class UserSettings: ObservableObject {
    public static let shared = UserSettings()

    // MARK: - General Settings Keys
    @AppStorage("defaultFormat") public var defaultFormat: String = "WEBP"
    @AppStorage("defaultQuality") public var defaultQuality: Int = 85
    @AppStorage("preserveMetadata") public var preserveMetadata: Bool = true
    @AppStorage("autoFitOnOpen") public var autoFitOnOpen: Bool = true

    // MARK: - Performance & RAM Settings Keys
    @AppStorage("workerCount") public var workerCount: Int = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)
    @AppStorage("maxCacheMemoryMB") public var maxCacheMemoryMB: Int = 100

    // MARK: - Canvas & Appearance Keys
    @AppStorage("canvasBackground") public var canvasBackground: String = "Neutral Dark"
    @AppStorage("zoomSensitivity") public var zoomSensitivity: Double = 1.25

    public init() {}

    /// Clears the in-memory thumbnail and preview cache.
    public func clearThumbnailCache() {
        ThumbnailCache.shared.removeAll()
    }
}
