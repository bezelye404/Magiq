//
//  MagickCLIResult.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Foundation

// MARK: - MagickCLIResult

/// Encapsulates the execution output and termination status of an ImageMagick CLI process.
public struct MagickCLIResult: Equatable, Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String
    public let duration: TimeInterval

    public var isSuccess: Bool {
        return self.exitCode == 0
    }

    public init(exitCode: Int32, stdout: String, stderr: String, duration: TimeInterval) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.duration = duration
    }
}
