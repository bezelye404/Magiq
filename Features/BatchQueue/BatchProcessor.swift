//
//  BatchProcessor.swift
//  Magiq
//

import AppKit
import Foundation

// MARK: - BatchProcessor

/// Coordinates parallel batch processing over a bounded TaskGroup worker pool.
public final class BatchProcessor: Sendable {
    public static let shared = BatchProcessor()

    private init() {}

    /// Processes a collection of `BatchItem`s respecting the concurrency limit.
    public func process(
        items: [BatchItem],
        operations: [any ImageOperation],
        targetFormat: String,
        outputDirectory: URL?,
        maxConcurrentWorkers: Int,
        onItemUpdate: @escaping @Sendable (BatchItem, BatchItemStatus) -> Void
    ) async {
        guard !items.isEmpty else { return }

        let workers = max(1, maxConcurrentWorkers)

        // Queue iterator protected by an actor
        let iterator = QueueIterator(items: items)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<workers {
                group.addTask {
                    while !Task.isCancelled {
                        guard let item = await iterator.nextPendingItem() else {
                            break
                        }

                        onItemUpdate(item, .processing(progress: 0.1))

                        let startTime = CFAbsoluteTimeGetCurrent()
                        let ext = targetFormat.lowercased()
                        let baseName = item.sourceURL.deletingPathExtension().lastPathComponent

                        let destinationDirectory = outputDirectory ?? item.sourceURL.deletingLastPathComponent()
                        let destinationURL = destinationDirectory.appendingPathComponent("\(baseName)-magiq.\(ext)")

                        do {
                            _ = try await ImagePipeline.shared.export(
                                from: item.sourceURL,
                                to: destinationURL,
                                operations: operations
                            )

                            let duration = CFAbsoluteTimeGetCurrent() - startTime
                            let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0

                            onItemUpdate(item, .completed(
                                outputURL: destinationURL,
                                outputSizeBytes: outputSize,
                                duration: duration
                            ))
                        } catch {
                            onItemUpdate(item, .failed(errorDescription: error.localizedDescription))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - QueueIterator Actor

private actor QueueIterator {
    private var pendingItems: [BatchItem]

    init(items: [BatchItem]) {
        self.pendingItems = items.filter { $0.status == .pending }
    }

    func nextPendingItem() -> BatchItem? {
        guard !self.pendingItems.isEmpty else { return nil }
        return self.pendingItems.removeFirst()
    }
}
