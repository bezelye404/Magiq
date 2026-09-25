//
//  WandSession.swift
//  Magiq
//

import Foundation
import os

// MARK: - WandSession

public final class WandSession: @unchecked Sendable {
    public static let shared = WandSession()

    private let lock = NSLock()
    private var isInitialized = false

    private init() {}

    // MARK: - Lifecycle

    public func ensureInitialized() {
        self.lock.lock()
        defer { self.lock.unlock() }

        guard !self.isInitialized else { return }

        self.configureResourcePaths()
        MagickWandGenesis()
        self.isInitialized = true
    }

    public func terminate() {
        self.lock.lock()
        defer { self.lock.unlock() }

        guard self.isInitialized else { return }
        MagickWandTerminus()
        self.isInitialized = false
    }

    // MARK: - Resource Paths

    private func configureResourcePaths() {
        let bundle = Bundle.main
        let distPath: String
        if let resourcePath = bundle.resourcePath,
           FileManager.default.fileExists(atPath: "\(resourcePath)/ImageMagickDistribution") {
            distPath = "\(resourcePath)/ImageMagickDistribution"
        } else {
            distPath = "\(FileManager.default.currentDirectoryPath)/Resources/ImageMagickDistribution"
        }

        setenv("MAGICK_HOME", distPath, 0)
        setenv("MAGICK_CODER_MODULE_PATH", "\(distPath)/modules/coders", 0)
        setenv("MAGICK_CONFIGURE_PATH", "\(distPath)/etc/ImageMagick-7", 0)
    }

    deinit {
        if self.isInitialized {
            MagickWandTerminus()
        }
    }
}
