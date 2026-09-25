//
//  BatchQueueManager.swift
//  Magiq
//

import Combine
import Foundation

// MARK: - BatchQueueManager

@MainActor
public final class BatchQueueManager: ObservableObject {
    public static let shared = BatchQueueManager()

    @Published public private(set) var items: [BatchItem] = []
    @Published public private(set) var isProcessing: Bool = false
    @Published public var selectedPreset: Preset?
    @Published public var outputDirectory: URL?
    @Published public var watchedFolderURL: URL?
    @Published public var isWatchingFolder: Bool = false

    private var folderWatcher: FolderWatcher?
    private var processingTask: Task<Void, Never>?

    private let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "webp", "heic", "tiff", "tif", "avif", "bmp", "gif", "dng", "cr2", "arw"
    ]

    public init() {
        self.selectedPreset = PresetStore.shared.presets.first
    }

    // MARK: - Computed Statistics

    public var totalCount: Int { self.items.count }

    public var completedCount: Int {
        self.items.filter {
            if case .completed = $0.status { return true }
            return false
        }.count
    }

    public var failedCount: Int {
        self.items.filter {
            if case .failed = $0.status { return true }
            return false
        }.count
    }

    public var pendingCount: Int {
        self.items.filter { $0.status == .pending }.count
    }

    public var overallProgress: Double {
        guard self.totalCount > 0 else { return 0.0 }
        let finished = self.completedCount + self.failedCount
        return Double(finished) / Double(self.totalCount)
    }

    public var totalBytesSaved: Int64 {
        var saved: Int64 = 0
        for item in self.items {
            if case .completed(_, let outSize, _) = item.status {
                if item.originalSizeBytes > outSize {
                    saved += (item.originalSizeBytes - outSize)
                }
            }
        }
        return saved
    }

    public var totalBytesSavedFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self.totalBytesSaved)
    }

    // MARK: - Item Management

    public func addFiles(urls: [URL]) {
        for url in urls {
            let ext = url.pathExtension.lowercased()
            if self.supportedExtensions.contains(ext) {
                if !self.items.contains(where: { $0.sourceURL == url }) {
                    self.items.append(BatchItem(sourceURL: url))
                }
            }
        }
    }

    public func addFolder(url: URL) {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        var foundURLs: [URL] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if self.supportedExtensions.contains(ext) {
                foundURLs.append(fileURL)
            }
        }
        self.addFiles(urls: foundURLs)
    }

    public func removeItem(id: UUID) {
        self.items.removeAll { $0.id == id }
    }

    public func clearCompleted() {
        self.items.removeAll {
            if case .completed = $0.status { return true }
            return false
        }
    }

    public func clearAll() {
        self.cancelProcessing()
        self.items.removeAll()
    }

    // MARK: - Processing Execution

    public func startProcessing() {
        guard !self.isProcessing else { return }
        guard let preset = self.selectedPreset else { return }

        self.isProcessing = true
        let operations = preset.allOperations
        let format = preset.outputFormat
        let outDir = self.outputDirectory
        let workers = UserSettings.shared.workerCount

        self.processingTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let pendingItems = await self.items.filter { $0.status == .pending }

            await BatchProcessor.shared.process(
                items: pendingItems,
                operations: operations,
                targetFormat: format,
                outputDirectory: outDir,
                maxConcurrentWorkers: workers,
                onItemUpdate: { item, status in
                    Task { @MainActor in
                        item.status = status
                    }
                }
            )

            await MainActor.run {
                self.isProcessing = false
            }
        }
    }

    public func cancelProcessing() {
        self.processingTask?.cancel()
        self.processingTask = nil
        self.isProcessing = false

        for item in self.items where !item.status.isTerminal {
            item.status = .cancelled
        }
    }

    // MARK: - Folder Watch

    public func startWatching(folder: URL) {
        self.stopWatching()
        self.watchedFolderURL = folder
        self.isWatchingFolder = true

        self.folderWatcher = FolderWatcher(folderURL: folder) { [weak self] newURLs in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.addFiles(urls: newURLs)
                if !self.isProcessing {
                    self.startProcessing()
                }
            }
        }
    }

    public func stopWatching() {
        self.folderWatcher?.stop()
        self.folderWatcher = nil
        self.watchedFolderURL = nil
        self.isWatchingFolder = false
    }
}
