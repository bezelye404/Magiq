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

    @MainActor
    func testSandboxPermissionsReset() {
        let settings = UserSettings.shared
        let defaults = UserDefaults.standard
        defaults.set("dummy-bookmark-data".data(using: .utf8), forKey: "FolderBookmark_123")
        defaults.set("/path/to/recent", forKey: "recentDocumentPaths")

        // Execute sandbox reset
        settings.resetSandboxPermissions()

        // Verify bookmark keys were stripped
        XCTAssertNil(defaults.object(forKey: "FolderBookmark_123"))
        XCTAssertNil(defaults.object(forKey: "recentDocumentPaths"))
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

    // MARK: - Levels, Artistic Tone & Trim Tests

    func testLevelsAndToneOperations() throws {
        // 1. Levels Operation
        let levels = LevelsOperation(blackPoint: 10.0, gamma: 1.2, whitePoint: 240.0)
        XCTAssertFalse(levels.isIdentity)
        XCTAssertEqual(levels.name, "Levels & Gamma")
        XCTAssertFalse(levels.cliArguments.isEmpty)

        let defaultLevels = LevelsOperation()
        XCTAssertTrue(defaultLevels.isIdentity)
        XCTAssertTrue(defaultLevels.cliArguments.isEmpty)

        // 2. Artistic Tone Operation
        let tone = ArtisticToneOperation(sepia: 60.0, negate: true, denoise: 1.5)
        XCTAssertFalse(tone.isIdentity)
        XCTAssertEqual(tone.name, "Tone & Special Effects")
        XCTAssertTrue(tone.cliArguments.contains("-negate"))
        XCTAssertTrue(tone.cliArguments.contains("-sepia-tone"))

        let defaultTone = ArtisticToneOperation()
        XCTAssertTrue(defaultTone.isIdentity)
        XCTAssertTrue(defaultTone.cliArguments.isEmpty)

        // 3. Trim Operation
        let trim = TrimOperation(fuzzPercent: 10.0)
        XCTAssertEqual(trim.name, "Auto-Trim Borders")
        XCTAssertEqual(trim.cliArguments, ["-fuzz", "10%", "-trim", "+repage"])

        // 4. Test apply to actual ImageWand canvas
        let wand = try ImageWand()
        try wand.createBlank(width: 80, height: 80, background: "white")
        try levels.apply(to: wand)
        try tone.apply(to: wand)
        XCTAssertEqual(wand.width, 80)
        XCTAssertEqual(wand.height, 80)

        // 5. Test pipeline serialization with new operations
        let pipeline: [PipelineOperation] = [
            .levels(levels),
            .artisticTone(tone),
            .trim(trim)
        ]
        let data = try JSONEncoder().encode(pipeline)
        let decoded = try JSONDecoder().decode([PipelineOperation].self, from: data)
        XCTAssertEqual(pipeline, decoded)
    }

    @MainActor
    func testViewModelWithNewOperations() {
        let vm = SingleDocumentViewModel()
        vm.blackPoint = 15.0
        vm.gammaPoint = 1.25
        vm.whitePoint = 235.0
        vm.sepia = 45.0
        vm.negate = true
        vm.isAutoTrimmed = true
        vm.trimFuzz = 8.0

        let ops = vm.buildPipelineOperations()
        XCTAssertTrue(ops.contains { if case .levels = $0 { return true }; return false })
        XCTAssertTrue(ops.contains { if case .artisticTone = $0 { return true }; return false })
        XCTAssertTrue(ops.contains { if case .trim = $0 { return true }; return false })

        // Reset
        vm.resetParameters()
        XCTAssertEqual(vm.blackPoint, 0.0)
        XCTAssertEqual(vm.gammaPoint, 1.0)
        XCTAssertEqual(vm.whitePoint, 255.0)
        XCTAssertEqual(vm.sepia, 0.0)
        XCTAssertFalse(vm.negate)
        XCTAssertFalse(vm.isAutoTrimmed)
    }

    // MARK: - EXIF & Metadata Inspector Tests

    func testMetadataExtractionAndFormatting() {
        let sampleProps = [
            "exif:Make": "Sony",
            "exif:Model": "ILCE-7RM5",
            "exif:LensModel": "FE 50mm F1.2 GM",
            "exif:FNumber": "28/10",
            "exif:ExposureTime": "1/500",
            "exif:PhotographicSensitivity": "100",
            "exif:FocalLength": "50/1",
            "exif:GPSLatitude": "41/1, 0/1, 23/1"
        ]

        let meta = ImageMetadata(
            width: 9504,
            height: 6336,
            format: "RAW",
            colorspace: "Display P3",
            depth: 16,
            fileSize: 64 * 1024 * 1024,
            properties: sampleProps
        )

        XCTAssertTrue(meta.hasCameraData)
        XCTAssertTrue(meta.hasGPS)
        XCTAssertEqual(meta.cameraModel, "Sony ILCE-7RM5")
        XCTAssertEqual(meta.lensModel, "FE 50mm F1.2 GM")
        XCTAssertEqual(meta.aperture, "ƒ/2.8")
        XCTAssertEqual(meta.shutterSpeed, "1/500s")
        XCTAssertEqual(meta.iso, "ISO 100")
        XCTAssertEqual(meta.focalLength, "50mm")
        XCTAssertFalse(meta.formattedSummary.isEmpty)
        XCTAssertTrue(meta.formattedSummary.contains("Sony ILCE-7RM5"))
        XCTAssertTrue(meta.formattedSummary.contains("ƒ/2.8"))
    }

    // MARK: - Multi-Page & Pagination Tests

    @MainActor
    func testMultiPageNavigationAndWandPagination() throws {
        let vm = SingleDocumentViewModel()
        XCTAssertEqual(vm.pageCount, 1)
        XCTAssertEqual(vm.currentPageIndex, 0)
        XCTAssertFalse(vm.exportAllPages)

        // Simulate multi-page document loaded
        vm.pageCount = 5
        vm.nextPage()
        XCTAssertEqual(vm.currentPageIndex, 1)

        vm.selectPage(index: 4)
        XCTAssertEqual(vm.currentPageIndex, 4)

        // Boundary check: cannot go beyond last page
        vm.nextPage()
        XCTAssertEqual(vm.currentPageIndex, 4)

        vm.previousPage()
        XCTAssertEqual(vm.currentPageIndex, 3)

        // Invalid index bounds check
        vm.selectPage(index: 10)
        XCTAssertEqual(vm.currentPageIndex, 3)

        vm.selectPage(index: -1)
        XCTAssertEqual(vm.currentPageIndex, 3)

        // ImageWand ping on non-existent file returns fallback 1
        let dummyURL = URL(fileURLWithPath: "/nonexistent/test.pdf")
        let pingCount = ImageWand.pingPageCount(from: dummyURL)
        XCTAssertEqual(pingCount, 1)

        // ImageWand single image count
        let wand = try ImageWand()
        try wand.createBlank(width: 50, height: 50)
        XCTAssertEqual(wand.imageCount, 1)
        XCTAssertEqual(wand.currentImageIndex, 0)
    }

    // MARK: - Quick Look Extension Tests

    func testQuickLookPreviewProviderInstantiation() {
        let provider = PreviewProvider()
        XCTAssertNotNil(provider)
    }

    // MARK: - Colorspace, Bit Depth & Quantize Tests

    @MainActor
    func testColorspaceBitDepthAndQuantizeOperations() throws {
        let wand = try ImageWand()
        try wand.createBlank(width: 80, height: 80, background: "coral")

        // 1. Colorspace Transformation
        let cmykOp = ColorspaceOperation(colorspace: "CMYK")
        XCTAssertFalse(cmykOp.isIdentity)
        XCTAssertEqual(cmykOp.cliArguments, ["-colorspace", "CMYK"])
        try cmykOp.apply(to: wand)
        XCTAssertEqual(wand.colorspace, "CMYK")

        let srgbOp = ColorspaceOperation(colorspace: "sRGB")
        XCTAssertTrue(srgbOp.isIdentity)
        XCTAssertTrue(srgbOp.cliArguments.isEmpty)

        // 2. Bit Depth
        let depth16Op = BitDepthOperation(depth: 16)
        XCTAssertFalse(depth16Op.isIdentity)
        XCTAssertEqual(depth16Op.cliArguments, ["-depth", "16"])
        try depth16Op.apply(to: wand)
        XCTAssertEqual(wand.depth, 16)

        let depth8Op = BitDepthOperation(depth: 8)
        XCTAssertTrue(depth8Op.isIdentity)

        // 3. Palette Quantization
        let quantOp = QuantizeOperation(numberColors: 32, dither: true)
        XCTAssertEqual(quantOp.numberColors, 32)
        XCTAssertEqual(quantOp.cliArguments, ["-colors", "32", "-dither", "FloydSteinberg"])
        try quantOp.apply(to: wand)

        // 4. ViewModel Integration
        let vm = SingleDocumentViewModel()
        XCTAssertEqual(vm.targetColorspace, "sRGB")
        XCTAssertEqual(vm.bitDepth, 8)
        XCTAssertEqual(vm.quantizeColors, 0)

        vm.targetColorspace = "CMYK"
        vm.bitDepth = 16
        vm.quantizeColors = 64

        let ops = vm.buildPipelineOperations()
        XCTAssertTrue(ops.contains(where: { if case .colorspace(let op) = $0 { return op.colorspace == "CMYK" }; return false }))
        XCTAssertTrue(ops.contains(where: { if case .bitDepth(let op) = $0 { return op.depth == 16 }; return false }))
        XCTAssertTrue(ops.contains(where: { if case .quantize(let op) = $0 { return op.numberColors == 64 }; return false }))

        vm.resetParameters()
        XCTAssertEqual(vm.targetColorspace, "sRGB")
        XCTAssertEqual(vm.bitDepth, 8)
        XCTAssertEqual(vm.quantizeColors, 0)
    }

    @MainActor
    func testBorderAndFrameOperations() throws {
        let wand = try ImageWand()
        try wand.createBlank(width: 100, height: 100, background: "blue")
        XCTAssertEqual(wand.width, 100)
        XCTAssertEqual(wand.height, 100)

        // 1. Border
        let borderOp = BorderOperation(width: 10, height: 10, color: "black")
        XCTAssertFalse(borderOp.isIdentity)
        XCTAssertEqual(borderOp.cliArguments, ["-bordercolor", "black", "-border", "10x10"])
        try borderOp.apply(to: wand)
        // With 10px on each side (left/right, top/bottom), width increases by 20, height by 20
        XCTAssertEqual(wand.width, 120)
        XCTAssertEqual(wand.height, 120)

        let identityBorder = BorderOperation(width: 0, height: 0, color: "black")
        XCTAssertTrue(identityBorder.isIdentity)
        XCTAssertTrue(identityBorder.cliArguments.isEmpty)

        // 2. 3D Beveled Frame
        let frameOp = FrameOperation(width: 15, height: 15, innerBevel: 2, outerBevel: 2, color: "#808080")
        XCTAssertFalse(frameOp.isIdentity)
        XCTAssertEqual(frameOp.cliArguments, ["-mattecolor", "#808080", "-frame", "15x15+2+2"])
        try frameOp.apply(to: wand)
        // With 15px frame on each side, width increases by 30, height by 30
        XCTAssertEqual(wand.width, 150)
        XCTAssertEqual(wand.height, 150)

        // 3. ViewModel Integration
        let vm = SingleDocumentViewModel()
        XCTAssertEqual(vm.borderWidth, 0)
        XCTAssertEqual(vm.borderHeight, 0)
        XCTAssertFalse(vm.isFrameEnabled)

        vm.borderWidth = 12
        vm.borderHeight = 12
        vm.borderColor = "white"
        vm.isFrameEnabled = true
        vm.frameWidth = 20
        vm.frameHeight = 20
        vm.frameColor = "gold"

        let ops = vm.buildPipelineOperations()
        XCTAssertTrue(ops.contains(where: {
            if case .border(let op) = $0 {
                return op.width == 12 && op.height == 12 && op.color == "white"
            }
            return false
        }))
        XCTAssertTrue(ops.contains(where: {
            if case .frame(let op) = $0 {
                return op.width == 20 && op.height == 20 && op.color == "gold"
            }
            return false
        }))

        vm.resetParameters()
        XCTAssertEqual(vm.borderWidth, 0)
        XCTAssertEqual(vm.borderHeight, 0)
        XCTAssertFalse(vm.isFrameEnabled)
    }

    @MainActor
    func testArtisticAndStylizeFilters() throws {
        let wand = try ImageWand()
        try wand.createBlank(width: 80, height: 80, background: "green")

        // 1. Oil Paint
        let oilOp = OilPaintOperation(radius: 3.0)
        XCTAssertFalse(oilOp.isIdentity)
        XCTAssertEqual(oilOp.cliArguments, ["-paint", "3.0"])
        try oilOp.apply(to: wand)

        // 2. Charcoal
        let charcoalOp = CharcoalOperation(radius: 2.0, sigma: 1.0)
        XCTAssertFalse(charcoalOp.isIdentity)
        XCTAssertEqual(charcoalOp.cliArguments, ["-charcoal", "2.0x1.0"])
        try charcoalOp.apply(to: wand)

        // 3. Sketch
        let sketchOp = SketchOperation(radius: 2.0, sigma: 1.0, angle: 45.0)
        XCTAssertFalse(sketchOp.isIdentity)
        XCTAssertEqual(sketchOp.cliArguments, ["-sketch", "2.0x1.0+45"])
        try sketchOp.apply(to: wand)

        // 4. Emboss
        let embossOp = EmbossOperation(radius: 1.5, sigma: 1.0)
        XCTAssertFalse(embossOp.isIdentity)
        XCTAssertEqual(embossOp.cliArguments, ["-emboss", "1.5x1.0"])
        try embossOp.apply(to: wand)

        // 5. Edge Detect
        let edgeOp = EdgeDetectOperation(radius: 2.0)
        XCTAssertFalse(edgeOp.isIdentity)
        XCTAssertEqual(edgeOp.cliArguments, ["-edge", "2.0"])
        try edgeOp.apply(to: wand)

        // 6. Add Noise
        let noiseOp = AddNoiseOperation(noiseType: .gaussian, attenuate: 1.5)
        XCTAssertFalse(noiseOp.isIdentity)
        XCTAssertEqual(noiseOp.cliArguments, ["-attenuate", "1.50", "+noise", "Gaussian"])
        try noiseOp.apply(to: wand)

        // 7. ViewModel Integration
        let vm = SingleDocumentViewModel()
        vm.oilPaintRadius = 4.0
        vm.charcoalRadius = 3.0
        vm.sketchRadius = 2.0
        vm.embossRadius = 1.0
        vm.edgeRadius = 2.5
        vm.noiseAmount = 1.2
        vm.noiseType = .uniform

        let ops = vm.buildPipelineOperations()
        XCTAssertTrue(ops.contains(where: { if case .oilPaint(let op) = $0 { return op.radius == 4.0 }; return false }))
        XCTAssertTrue(ops.contains(where: { if case .charcoal(let op) = $0 { return op.radius == 3.0 }; return false }))
        XCTAssertTrue(ops.contains(where: { if case .sketch(let op) = $0 { return op.radius == 2.0 }; return false }))
        XCTAssertTrue(ops.contains(where: { if case .emboss(let op) = $0 { return op.radius == 1.0 }; return false }))
        XCTAssertTrue(ops.contains(where: { if case .edge(let op) = $0 { return op.radius == 2.5 }; return false }))
        XCTAssertTrue(ops.contains(where: { if case .addNoise(let op) = $0 { return op.attenuate == 1.2 && op.noiseType == .uniform }; return false }))

        vm.resetParameters()
        XCTAssertEqual(vm.oilPaintRadius, 0.0)
        XCTAssertEqual(vm.charcoalRadius, 0.0)
        XCTAssertEqual(vm.sketchRadius, 0.0)
        XCTAssertEqual(vm.embossRadius, 0.0)
        XCTAssertEqual(vm.edgeRadius, 0.0)
        XCTAssertEqual(vm.noiseAmount, 0.0)
    }

    func testMontageAndCompareOperations() throws {
        let wandA = try ImageWand()
        try wandA.createBlank(width: 50, height: 50, background: "red")

        let wandB = try ImageWand()
        try wandB.createBlank(width: 50, height: 50, background: "blue")

        // 1. Horizontal Append (Side by side)
        let horizAppended = try wandA.appended(with: wandB, stackVertical: false)
        XCTAssertEqual(horizAppended.width, 100)
        XCTAssertEqual(horizAppended.height, 50)

        // 2. Vertical Append (Stacked)
        let vertAppended = try wandA.appended(with: wandB, stackVertical: true)
        XCTAssertEqual(vertAppended.width, 50)
        XCTAssertEqual(vertAppended.height, 100)

        // 3. Image Compare (Diff)
        let compareResult = try wandA.compare(with: wandB)
        XCTAssertNotNil(compareResult.differenceWand)
        XCTAssertGreaterThan(compareResult.distortion, 0.0)

        // Compare identical images
        let identicalCompare = try wandA.compare(with: wandA)
        XCTAssertEqual(identicalCompare.distortion, 0.0, accuracy: 0.001)
    }
}

