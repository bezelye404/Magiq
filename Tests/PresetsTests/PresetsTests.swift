//
//  PresetsTests.swift
//  MagiqTests
//

import XCTest
@testable import Magiq

final class PresetsTests: XCTestCase {
    @MainActor
    func testBuiltInPresetsExist() {
        let store = PresetStore.shared
        XCTAssertFalse(store.presets.isEmpty)

        let webpPreset = store.presets.first(where: { $0.name == "Web-Optimized WebP" })
        XCTAssertNotNil(webpPreset)
        XCTAssertEqual(webpPreset?.outputFormat, "WEBP")
        XCTAssertEqual(webpPreset?.quality, 82)
        XCTAssertTrue(webpPreset?.stripMetadata ?? false)
    }

    @MainActor
    func testPresetDuplicationAndDeletion() {
        let store = PresetStore.shared
        guard let first = store.presets.first else {
            XCTFail("No presets found")
            return
        }

        let copy = store.duplicate(preset: first)
        XCTAssertTrue(copy.name.contains("(Copy)"))
        XCTAssertFalse(copy.isBuiltIn)
        XCTAssertTrue(store.presets.contains(where: { $0.id == copy.id }))

        store.delete(presetId: copy.id)
        XCTAssertFalse(store.presets.contains(where: { $0.id == copy.id }))
    }
}
