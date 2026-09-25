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
        var distPath: String?

        if let resourcePath = bundle.resourcePath,
           FileManager.default.fileExists(atPath: "\(resourcePath)/ImageMagickDistribution") {
            distPath = "\(resourcePath)/ImageMagickDistribution"
        } else if FileManager.default.fileExists(atPath: "\(FileManager.default.currentDirectoryPath)/Resources/ImageMagickDistribution") {
            distPath = "\(FileManager.default.currentDirectoryPath)/Resources/ImageMagickDistribution"
        } else if let sourceRoot = ProcessInfo.processInfo.environment["SRCROOT"],
                  FileManager.default.fileExists(atPath: "\(sourceRoot)/Resources/ImageMagickDistribution") {
            distPath = "\(sourceRoot)/Resources/ImageMagickDistribution"
        }

        if let dist = distPath {
            setenv("MAGICK_HOME", dist, 1)
            setenv("MAGICK_CODER_MODULE_PATH", "\(dist)/modules/coders", 1)
            setenv("MAGICK_CONFIGURE_PATH", "\(dist)/etc/ImageMagick-7", 1)
            setenv("DYLD_LIBRARY_PATH", "\(dist)/lib", 0)
        } else if FileManager.default.fileExists(atPath: "/opt/homebrew/Cellar/imagemagick") {
            let cellar = "/opt/homebrew/Cellar/imagemagick"
            if let versions = try? FileManager.default.contentsOfDirectory(atPath: cellar),
               let latest = versions.sorted().last {
                let homebrewCoders = "\(cellar)/\(latest)/lib/ImageMagick/modules-Q16HDRI/coders"
                setenv("MAGICK_CODER_MODULE_PATH", homebrewCoders, 1)
                setenv("MAGICK_CONFIGURE_PATH", "\(cellar)/\(latest)/etc/ImageMagick-7", 1)
            }
        }
    }

    deinit {
        if self.isInitialized {
            MagickWandTerminus()
        }
    }
}
