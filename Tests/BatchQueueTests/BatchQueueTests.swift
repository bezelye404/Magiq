//
//  BatchQueueTests.swift
//  MagiqTests
//

import XCTest
@testable import Magiq

final class BatchQueueTests: XCTestCase {
    @MainActor
    func testBatchItemAndSavings() {
        let dummyURL = URL(fileURLWithPath: "/tmp/sample_image.png")
        let item = BatchItem(sourceURL: dummyURL)

        XCTAssertEqual(item.fileName, "sample_image.png")
        XCTAssertEqual(item.status, .pending)

        let savings = item.sizeSavingsFormatted(outputBytes: 500)
        // With originalSizeBytes == 0 in unit test, savings returns nil safely
        XCTAssertNil(savings)
    }

    @MainActor
    func testBatchQueueManagerLifecycle() {
        let manager = BatchQueueManager()
        XCTAssertEqual(manager.items.count, 0)
        XCTAssertEqual(manager.isProcessing, false)
        XCTAssertNotNil(manager.selectedPreset)

        let urls = [
            URL(fileURLWithPath: "/tmp/test1.jpg"),
            URL(fileURLWithPath: "/tmp/test2.png"),
            URL(fileURLWithPath: "/tmp/test3.webp")
        ]
        manager.addFiles(urls: urls)

        XCTAssertEqual(manager.items.count, 3)
        XCTAssertEqual(manager.totalCount, 3)
        XCTAssertEqual(manager.pendingCount, 3)
        XCTAssertEqual(manager.completedCount, 0)

        manager.clearAll()
        XCTAssertEqual(manager.items.count, 0)
    }
}
