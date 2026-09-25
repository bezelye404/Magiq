//
//  SingleDocumentViewModelTests.swift
//  MagiqTests
//

import XCTest
@testable import Magiq

final class SingleDocumentViewModelTests: XCTestCase {
    @MainActor
    func testViewModelInitialState() {
        let vm = SingleDocumentViewModel()

        XCTAssertNil(vm.currentImageURL)
        XCTAssertNil(vm.metadata)
        XCTAssertNil(vm.previewImage)
        XCTAssertNil(vm.originalPreviewImage)
        XCTAssertFalse(vm.isRendering)
        XCTAssertNil(vm.errorMessage)
        XCTAssertTrue(vm.showInspector)

        XCTAssertEqual(vm.rotationDegrees, 0.0)
        XCTAssertFalse(vm.flipHorizontal)
        XCTAssertFalse(vm.flipVertical)
        XCTAssertEqual(vm.brightness, 0.0)
        XCTAssertEqual(vm.contrast, 0.0)
        XCTAssertEqual(vm.saturation, 0.0)
        XCTAssertFalse(vm.autoLevel)
        XCTAssertEqual(vm.sharpen, 0.0)
        XCTAssertEqual(vm.blur, 0.0)
        XCTAssertFalse(vm.stripMetadata)
        XCTAssertEqual(vm.targetFormat, "WEBP")
        XCTAssertEqual(vm.quality, 85)
    }

    @MainActor
    func testPipelineBuilderFromViewModelProperties() {
        let vm = SingleDocumentViewModel()
        vm.resizeWidth = 800
        vm.resizeHeight = 600
        vm.rotationDegrees = 90.0
        vm.flipHorizontal = true
        vm.brightness = 0.2
        vm.contrast = 0.1
        vm.saturation = 0.05
        vm.autoLevel = true
        vm.sharpen = 1.5
        vm.blur = 0.5
        vm.stripMetadata = true
        vm.targetFormat = "PNG"
        vm.quality = 90

        let ops = vm.buildPipelineOperations()
        XCTAssertEqual(ops.count, 8)

        // Verify resize
        let hasResize = ops.contains {
            if case .resize(let r) = $0 { return r.width == 800 && r.height == 600 }
            return false
        }
        XCTAssertTrue(hasResize)

        // Verify rotation
        let hasRotate = ops.contains {
            if case .rotate(let r) = $0 { return r.degrees == 90.0 }
            return false
        }
        XCTAssertTrue(hasRotate)

        // Verify format
        let hasFormat = ops.contains {
            if case .formatConvert(let f) = $0 { return f.format == "PNG" && f.quality == 90 }
            return false
        }
        XCTAssertTrue(hasFormat)
    }

    @MainActor
    func testUndoRedoViaViewModel() {
        let vm = SingleDocumentViewModel()

        let initialOps = vm.buildPipelineOperations()
        vm.history.reset(initialOperations: initialOps)

        // Make an edit
        let editOps: [PipelineOperation] = [
            .rotate(RotateOperation(degrees: 180.0)),
            .formatConvert(FormatConvertOperation(format: "JPEG", quality: 80))
        ]
        vm.history.push(stepName: "Rotate 180", operations: editOps)
        XCTAssertTrue(vm.history.canUndo)

        // Undo
        vm.performUndo()
        XCTAssertTrue(vm.history.canRedo)

        // Redo
        vm.performRedo()
        XCTAssertEqual(vm.rotationDegrees, 180.0)
        XCTAssertEqual(vm.targetFormat, "JPEG")
        XCTAssertEqual(vm.quality, 80)
    }

    @MainActor
    func testResetParameters() {
        let vm = SingleDocumentViewModel()
        vm.rotationDegrees = 45.0
        vm.flipHorizontal = true
        vm.brightness = 0.5
        vm.sharpen = 2.0

        vm.resetParameters()

        XCTAssertEqual(vm.rotationDegrees, 0.0)
        XCTAssertFalse(vm.flipHorizontal)
        XCTAssertEqual(vm.brightness, 0.0)
        XCTAssertEqual(vm.sharpen, 0.0)
        XCTAssertEqual(vm.quality, 85)
    }
}
