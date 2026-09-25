//
//  WandSession.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Foundation
import os

// MARK: - WandSession

/// Manages the global lifecycle of ImageMagick's Wand environment.
///
/// Ensures `MagickWandGenesis` is initialized once and `MagickWandTerminus` is called on teardown.
/// Configures runtime environment variables pointing to bundled coder modules and XML definitions.
public final class WandSession: @unchecked Sendable {
    public static let shared = WandSession()

    private let lock = NSLock()
    private var isInitialized = false

    private init() {}

    /// Ensures the ImageMagick environment is initialized and points to bundled resources.
    public func ensureInitialized() {
        self.lock.lock()
        defer { self.lock.unlock() }

        guard !self.isInitialized else { return }

        // Configure environment paths pointing to bundled resources
        self.configureResourcePaths()

        // Initialize ImageMagick Wand environment
        MagickWandGenesis()
        self.isInitialized = true
    }

    /// Terminates the ImageMagick Wand environment, releasing all global resources.
    public func terminate() {
        self.lock.lock()
        defer { self.lock.unlock() }

        guard self.isInitialized else { return }
        MagickWandTerminus()
        self.isInitialized = false
    }

    // MARK: - Private Helpers

    private func configureResourcePaths() {
        let bundle = Bundle.main

        // Check if running inside app bundle or falling back to local distribution
        let distPath: String
        if let resourcePath = bundle.resourcePath,
           FileManager.default.fileExists(atPath: "\(resourcePath)/ImageMagickDistribution") {
            distPath = "\(resourcePath)/ImageMagickDistribution"
        } else {
            // Local development path fallback
            distPath = "\(FileManager.default.currentDirectoryPath)/Resources/ImageMagickDistribution"
        }

        let modulesPath = "\(distPath)/modules/coders"
        let configPath = "\(distPath)/etc/ImageMagick-7"

        setenv("MAGICK_HOME", distPath, 0)
        setenv("MAGICK_CODER_MODULE_PATH", modulesPath, 0)
        setenv("MAGICK_CONFIGURE_PATH", configPath, 0)
    }

    deinit {
        if self.isInitialized {
            MagickWandTerminus()
        }
    }
}
