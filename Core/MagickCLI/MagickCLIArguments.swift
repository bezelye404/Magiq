//
//  MagickCLIArguments.swift
//  Magiq
//

import Foundation

// MARK: - MagickCLIArguments

public struct MagickCLIArguments: Sendable {
    private var arguments: [String] = []

    public init() {}

    public mutating func append(option: String, value: String? = nil) {
        self.arguments.append(option)
        if let value = value {
            self.arguments.append(value)
        }
    }

    public mutating func appendInputPath(_ path: String) {
        self.arguments.append(path)
    }

    public mutating func appendOutputPath(_ path: String) {
        self.arguments.append(path)
    }

    public var rawArguments: [String] {
        return self.arguments
    }
}
