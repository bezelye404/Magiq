//
//  MagickCLIArguments.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Foundation

// MARK: - MagickCLIArguments

/// Type-safe argument array builder for ImageMagick CLI invocations.
///
/// **Security Policy (AGENTS.md rule #6):**
/// CLI commands are strictly formed as arrays of individual string arguments.
/// Under no circumstances is shell string interpolation or `/bin/sh -c` used.
public struct MagickCLIArguments: Sendable {
    private var arguments: [String] = []

    public init() {}

    /// Appends a raw option and optional value (e.g. "-resize", "1920x1080").
    public mutating func append(option: String, value: String? = nil) {
        self.arguments.append(option)
        if let value = value {
            self.arguments.append(value)
        }
    }

    /// Appends an input file path.
    public mutating func appendInputPath(_ path: String) {
        self.arguments.append(path)
    }

    /// Appends an output file path.
    public mutating func appendOutputPath(_ path: String) {
        self.arguments.append(path)
    }

    /// Returns the raw argument array passed directly to `Process.arguments`.
    public var rawArguments: [String] {
        return self.arguments
    }
}
