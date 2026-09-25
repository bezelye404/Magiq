//
//  MagickCLIResult.swift
//  Magiq
//

import Foundation

// MARK: - MagickCLIResult

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
