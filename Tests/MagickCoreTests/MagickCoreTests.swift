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
}
