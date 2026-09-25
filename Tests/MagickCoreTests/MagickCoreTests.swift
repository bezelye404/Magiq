//
//  MagickCoreTests.swift
//  MagiqTests
//

import XCTest
@testable import Magiq

final class MagickCoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        WandSession.shared.ensureInitialized()
    }

    func testGeometryAspectFit() {
        let original = MagickGeometry(width: 4000, height: 2000)
        let bounds = MagickGeometry(width: 1000, height: 1000)
        let fitted = original.aspectFit(within: bounds)

        XCTAssertEqual(fitted.width, 1000)
        XCTAssertEqual(fitted.height, 500)
    }

    func testPixelWandAllocation() throws {
        let pixel = try PixelWandWrapper(color: "#FF0000")
        XCTAssertNotNil(pixel.pointer)
    }

    func testImageWandLifecycleAndCanvasCreation() throws {
        let wand = try ImageWand()
        XCTAssertNotNil(wand.pointer)
    }

    func testCreateBlankAndTransformations() throws {
        let wand = try ImageWand()
        try wand.createBlank(width: 200, height: 100, background: "blue")
        XCTAssertEqual(wand.width, 200)
        XCTAssertEqual(wand.height, 100)

        // Test flip and flop
        try wand.flip()
        try wand.flop()

        // Test color adjustments
        try wand.brightnessContrast(brightness: 10.0, contrast: 5.0)
        try wand.modulate(brightness: 100.0, saturation: 120.0, hue: 100.0)

        // Test auto level
        try wand.autoLevel()

        // Test sharpen and blur
        try wand.sharpen(radius: 0.0, sigma: 1.0)
        try wand.blur(radius: 0.0, sigma: 1.0)

        // Test strip
        try wand.strip()

        // Test NSImage conversion
        let nsImage = wand.makeNSImage()
        XCTAssertNotNil(nsImage)
    }

    func testImageOperationsPipeline() throws {
        let wand = try ImageWand()
        try wand.createBlank(width: 400, height: 200, background: "white")

        let ops: [any ImageOperation] = [
            FlipFlopOperation(horizontal: true, vertical: false),
            ColorAdjustOperation(brightness: 5, contrast: 5, saturation: 10),
            AutoLevelOperation(enabled: true),
            SharpenBlurOperation(sharpen: 1.0, blur: 0.0),
            StripMetadataOperation(enabled: true),
            ResizeOperation(width: 200, height: 100, maintainAspectRatio: true)
        ]

        for op in ops {
            try op.apply(to: wand)
            XCTAssertFalse(op.name.isEmpty)
        }

        XCTAssertEqual(wand.width, 200)
        XCTAssertEqual(wand.height, 100)
    }

    func testPipelineOperationSerialization() throws {
        let operations: [PipelineOperation] = [
            .resize(ResizeOperation(width: 800, height: 600)),
            .flipFlop(FlipFlopOperation(horizontal: true, vertical: false)),
            .colorAdjust(ColorAdjustOperation(brightness: 10, contrast: -5, saturation: 20)),
            .autoLevel(AutoLevelOperation(enabled: true)),
            .sharpenBlur(SharpenBlurOperation(sharpen: 1.5, blur: 0.0)),
            .stripMetadata(StripMetadataOperation(enabled: true)),
            .formatConvert(FormatConvertOperation(format: "WEBP", quality: 85))
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(operations)
        XCTAssertFalse(data.isEmpty)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([PipelineOperation].self, from: data)
        XCTAssertEqual(decoded.count, operations.count)
    }
}
