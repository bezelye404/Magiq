//
//  HistoryManager.swift
//  Magiq
//

import Combine
import Foundation

// MARK: - HistoryManager

/// Manages a bounded undo/redo history stack of recipe states.
@MainActor
public final class HistoryManager: ObservableObject {
    @Published public private(set) var pastSteps: [HistoryStep] = []
    @Published public private(set) var futureSteps: [HistoryStep] = []
    @Published public private(set) var currentStep: HistoryStep?

    private let maxCapacity: Int = 40

    public init() {}

    public var canUndo: Bool { !self.pastSteps.isEmpty }
    public var canRedo: Bool { !self.futureSteps.isEmpty }

    /// Records a new editing step, clearing any pending redo history.
    public func push(stepName: String, operations: [PipelineOperation]) {
        // If identical to current step, ignore duplicate push
        if let current = self.currentStep, current.state == operations {
            return
        }

        if let current = self.currentStep {
            self.pastSteps.append(current)
            if self.pastSteps.count > self.maxCapacity {
                self.pastSteps.removeFirst()
            }
        }

        self.futureSteps.removeAll()
        self.currentStep = HistoryStep(name: stepName, state: operations)
    }

    /// Reverts to the previous recipe state.
    public func undo() -> [PipelineOperation]? {
        guard let previous = self.pastSteps.popLast() else { return nil }

        if let current = self.currentStep {
            self.futureSteps.insert(current, at: 0)
        }
        self.currentStep = previous
        return previous.state
    }

    /// Re-applies the next undone recipe state.
    public func redo() -> [PipelineOperation]? {
        guard !self.futureSteps.isEmpty else { return nil }
        let next = self.futureSteps.removeFirst()

        if let current = self.currentStep {
            self.pastSteps.append(current)
        }
        self.currentStep = next
        return next.state
    }

    /// Resets the history with an initial clean state.
    public func reset(initialOperations: [PipelineOperation] = []) {
        self.pastSteps.removeAll()
        self.futureSteps.removeAll()
        self.currentStep = HistoryStep(name: "Original Image", state: initialOperations)
    }
}
