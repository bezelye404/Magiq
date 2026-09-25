//
//  FeaturesTests.swift
//  MagiqTests
//

import AppKit
import XCTest
@testable import Magiq

final class FeaturesTests: XCTestCase {

    // MARK: - Keyboard Shortcuts Tests

    @MainActor
    func testKeyboardShortcutDefaultsAndCustomization() {
        let manager = KeyboardShortcutManager.shared
        manager.resetAllToDefaults()

        // 1. Verify standard defaults
        let openShortcut = manager.shortcut(for: .openImage)
        XCTAssertEqual(openShortcut.key, "o")
        XCTAssertTrue(openShortcut.command)
        XCTAssertFalse(openShortcut.shift)
        XCTAssertEqual(openShortcut.displayString, "⌘O")

        let redoShortcut = manager.shortcut(for: .redo)
        XCTAssertEqual(redoShortcut.key, "z")
        XCTAssertTrue(redoShortcut.command)
        XCTAssertTrue(redoShortcut.shift)
        XCTAssertEqual(redoShortcut.displayString, "⇧⌘Z")

        // 2. Customize a shortcut
        manager.update(action: .openImage, key: "p", command: true, shift: true, option: false, control: false)
        let customOpen = manager.shortcut(for: .openImage)
        XCTAssertEqual(customOpen.key, "p")
        XCTAssertTrue(customOpen.shift)
        XCTAssertFalse(customOpen.isDefault)

        // 3. Reset individual shortcut
        manager.reset(action: .openImage)
        let resetOpen = manager.shortcut(for: .openImage)
        XCTAssertEqual(resetOpen.key, "o")
        XCTAssertTrue(resetOpen.isDefault)

        // 4. Reset all
        manager.update(action: .exportImage, key: "s", command: true, shift: false, option: false, control: false)
        manager.resetAllToDefaults()
        XCTAssertTrue(manager.shortcut(for: .exportImage).isDefault)
    }

    // MARK: - Privacy Settings Reset Tests

    @MainActor
    func testPrivacyResetFacility() {
        let settings = UserSettings.shared
        settings.preserveMetadata = false
        settings.stripMetadataByDefault = true

        // Add dummy item to cache
        ThumbnailCache.shared.insert(
            NSImage(size: NSSize(width: 10, height: 10)),
            for: URL(fileURLWithPath: "/tmp/dummy.png"),
            geometry: MagickGeometry(width: 10, height: 10)
        )

        // Execute Privacy Reset
        settings.resetPrivacySettings()

        // Verify state is restored to privacy-compliant factory defaults
        XCTAssertTrue(settings.preserveMetadata)
        XCTAssertFalse(settings.stripMetadataByDefault)
        XCTAssertTrue(settings.clearRecentFilesOnExit)

        // Verify cache is flushed
        let cached = ThumbnailCache.shared.image(
            for: URL(fileURLWithPath: "/tmp/dummy.png"),
            geometry: MagickGeometry(width: 10, height: 10)
        )
        XCTAssertNil(cached)
    }

    // MARK: - Live Histogram Tests

    func testHistogramCalculation() {
        // Create 100x100 solid test image
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()

        let hist = HistogramData.calculate(from: image)
        XCTAssertNotNil(hist)
        guard let data = hist else { return }

        XCTAssertEqual(data.red.count, 256)
        XCTAssertEqual(data.green.count, 256)
        XCTAssertEqual(data.blue.count, 256)
        XCTAssertEqual(data.luminance.count, 256)

        // Red channel peak should be at or near 255
        let peakRed = data.red.max() ?? 0
        XCTAssertEqual(peakRed, 1.0, accuracy: 0.001)
    }

    // MARK: - Target Size Optimizer Tests

    func testOptimizationResultModel() {
        let result = OptimizationResult(
            optimalQuality: 78,
            estimatedSizeBytes: 450 * 1024,
            targetSizeBytes: 500 * 1024,
            iterationsUsed: 4
        )

        XCTAssertEqual(result.optimalQuality, 78)
        XCTAssertEqual(result.iterationsUsed, 4)
        XCTAssertFalse(result.estimatedSizeFormatted.isEmpty)
        XCTAssertFalse(result.targetSizeFormatted.isEmpty)
    }

    // MARK: - Film Simulation & Watermark Tests

    func testFilmProfileAndWatermarkOperations() throws {
        // Test Watermark Operation
        let watermark = WatermarkOperation(
            text: "Copyright 2026",
            fontSize: 24,
            opacity: 0.8,
            position: .bottomRight
        )
        XCTAssertEqual(watermark.cliArguments, [
            "-gravity", "SouthEast",
            "-pointsize", "24",
            "-fill", "white",
            "-annotate", "+20+20", "Copyright 2026"
        ])

        // Test Film Profile Operation
        let film = ColorGradeOperation(profile: .portraWarm)
        XCTAssertEqual(film.cliArguments, ["-brightness-contrast", "4x6", "-modulate", "102,110,102"])

        // Test Pipeline Encoding
        let ops: [PipelineOperation] = [
            .watermark(watermark),
            .colorGrade(film)
        ]
        let encoded = try JSONEncoder().encode(ops)
        let decoded = try JSONDecoder().decode([PipelineOperation].self, from: encoded)
        XCTAssertEqual(ops, decoded)
    }
}
