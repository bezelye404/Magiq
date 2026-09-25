//
//  MagickError.swift
//  Magiq
//

import Foundation

// MARK: - MagickError

public enum MagickError: LocalizedError, Equatable {
    case wandAllocationFailed
    case imageReadFailed(reason: String)
    case imageWriteFailed(reason: String)
    case operationFailed(operation: String, reason: String)
    case exceptionRaised(severity: Int, message: String)
    case fileNotFound(url: URL)
    case securityScopedAccessDenied(url: URL)
    case cliExecutionFailed(exitCode: Int32, stderr: String)
    case invalidGeometry(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .wandAllocationFailed:
            return "Failed to allocate ImageMagick Wand in memory."
        case let .imageReadFailed(reason):
            return "Failed to read image: \(reason)"
        case let .imageWriteFailed(reason):
            return "Failed to write image: \(reason)"
        case let .operationFailed(operation, reason):
            return "Operation '\(operation)' failed: \(reason)"
        case let .exceptionRaised(severity, message):
            return "ImageMagick exception (severity \(severity)): \(message)"
        case let .fileNotFound(url):
            return "File not found at path: \(url.path)"
        case let .securityScopedAccessDenied(url):
            return "Permission denied accessing security-scoped bookmark: \(url.path)"
        case let .cliExecutionFailed(exitCode, stderr):
            return "ImageMagick CLI exited with code \(exitCode): \(stderr)"
        case let .invalidGeometry(geometry):
            return "Invalid geometry specification: \(geometry)"
        }
    }
}
