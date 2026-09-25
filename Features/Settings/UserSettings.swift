//
//  UserSettings.swift
//  Magiq
//

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

    public init() {}

    public func clearThumbnailCache() {
        ThumbnailCache.shared.removeAll()
    }
}
