//
//  HistoryStep.swift
//  Magiq
//

import Foundation

// MARK: - HistoryStep

/// A lightweight snapshot of an operation pipeline recipe at a specific point in time.
/// RAM Discipline (ARCHITECTURE.md): Stores operation parameter recipes only, NEVER full bitmap buffers.
public struct HistoryStep: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let timestamp: Date
    public let state: [PipelineOperation]

    public init(
        id: UUID = UUID(),
        name: String,
        timestamp: Date = Date(),
        state: [PipelineOperation]
    ) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.state = state
    }
}
