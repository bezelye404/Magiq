//
//  BatchItem.swift
//  Magiq
//

import AppKit
import Combine
import Foundation

// MARK: - BatchItemStatus

public enum BatchItemStatus: Equatable, Sendable {
    case pending
    case processing(progress: Double)
    case completed(outputURL: URL, outputSizeBytes: Int64, duration: TimeInterval)
    case failed(errorDescription: String)
    case cancelled

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .pending, .processing:
            return false
        }
    }
}

// MARK: - BatchItem

/// Represents a single file scheduled for batch processing.
public final class BatchItem: Identifiable, ObservableObject, @unchecked Sendable {
    public let id: UUID
    public let sourceURL: URL
    public let originalSizeBytes: Int64

    @Published public var status: BatchItemStatus
    @Published public var thumbnail: NSImage?

    public init(
        id: UUID = UUID(),
        sourceURL: URL,
        status: BatchItemStatus = .pending
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.status = status

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? NSNumber)?.int64Value ?? 0
        self.originalSizeBytes = fileSize
    }

    public var fileName: String {
        self.sourceURL.lastPathComponent
    }

    public var originalSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self.originalSizeBytes)
    }

    public func formattedOutputSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    public func sizeSavingsFormatted(outputBytes: Int64) -> String? {
        guard self.originalSizeBytes > 0 else { return nil }
        let diff = Double(self.originalSizeBytes - outputBytes)
        let percent = (diff / Double(self.originalSizeBytes)) * 100.0
        if percent > 0 {
            return "-\(Int(percent))%"
        } else {
            return "+\(Int(abs(percent)))%"
        }
    }
}
