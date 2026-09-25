//
//  MagickCLITests.swift
//  MagiqTests
//

import XCTest
@testable import Magiq

final class MagickCLITests: XCTestCase {
    func testArgumentsBuilder() {
        var args = MagickCLIArguments()
        args.appendInputPath("input.heic")
        args.append(option: "-resize", value: "800x600")
        args.append(option: "-quality", value: "85")
        args.appendOutputPath("output.webp")

        XCTAssertEqual(args.rawArguments, [
            "input.heic",
            "-resize",
            "800x600",
            "-quality",
            "85",
            "output.webp"
        ])
    }

    func testCLIVersionExecution() async throws {
        let result = try await MagickCLIExecutor.shared.execute(arguments: ["-version"])
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(result.stdout.contains("ImageMagick"))
    }
}
