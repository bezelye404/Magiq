//
//  Preset.swift
//  Magiq
//

import Foundation

// MARK: - Preset

/// A reusable, named recipe of image processing operations and export settings.
public struct Preset: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var description: String
    public var iconName: String
    public var isBuiltIn: Bool
    public var operations: [PipelineOperation]
    public var outputFormat: String
    public var quality: Int
    public var stripMetadata: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String = "slider.horizontal.3",
        isBuiltIn: Bool = false,
        operations: [PipelineOperation] = [],
        outputFormat: String = "WEBP",
        quality: Int = 85,
        stripMetadata: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.isBuiltIn = isBuiltIn
        self.operations = operations
        self.outputFormat = outputFormat.uppercased()
        self.quality = max(1, min(100, quality))
        self.stripMetadata = stripMetadata
    }

    /// Generates the full flat list of image operations to execute for this preset.
    public var allOperations: [any ImageOperation] {
        var ops: [any ImageOperation] = self.operations.map { $0 }
        if self.stripMetadata {
            ops.append(StripMetadataOperation(enabled: true))
        }
        ops.append(FormatConvertOperation(format: self.outputFormat, quality: self.quality))
        return ops
    }
}
