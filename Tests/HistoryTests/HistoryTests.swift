//
//  HistoryTests.swift
//  MagiqTests
//

import XCTest
@testable import Magiq

final class HistoryTests: XCTestCase {
    @MainActor
    func testHistoryPushAndUndoRedo() {
        let history = HistoryManager()
        history.reset()

        XCTAssertFalse(history.canUndo)
        XCTAssertFalse(history.canRedo)

        let step1: [PipelineOperation] = [
            .resize(ResizeOperation(width: 800, height: 600))
        ]
        history.push(stepName: "Resize", operations: step1)

        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.currentStep?.name, "Resize")

        let step2: [PipelineOperation] = [
            .resize(ResizeOperation(width: 800, height: 600)),
            .autoLevel(AutoLevelOperation(enabled: true))
        ]
        history.push(stepName: "Auto Level", operations: step2)

        XCTAssertEqual(history.pastSteps.count, 2)

        // Undo
        let reverted = history.undo()
        XCTAssertEqual(reverted, step1)
        XCTAssertTrue(history.canUndo)
        XCTAssertTrue(history.canRedo)
        XCTAssertEqual(history.currentStep?.name, "Resize")

        // Redo
        let redone = history.redo()
        XCTAssertEqual(redone, step2)
        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.currentStep?.name, "Auto Level")
    }
}
