//
//  FolderWatcher.swift
//  Magiq
//

import Foundation

// MARK: - FolderWatcher

/// Non-polling folder observer using DispatchSource file-system events.
public final class FolderWatcher: @unchecked Sendable {
    private let folderURL: URL
    private let securityScoped: SecurityScopedURL
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let onNewImages: @Sendable ([URL]) -> Void

    private var knownFiles: Set<String> = []
    private let lock = NSLock()

    private let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "webp", "heic", "tiff", "tif", "avif", "bmp", "gif", "dng", "cr2", "arw"
    ]

    public init(folderURL: URL, onNewImages: @escaping @Sendable ([URL]) -> Void) {
        self.folderURL = folderURL
        self.securityScoped = SecurityScopedURL(url: folderURL)
        self.onNewImages = onNewImages

        self.indexInitialFiles()
        self.startObserving()
    }

    deinit {
        self.stop()
    }

    public func stop() {
        self.lock.lock()
        defer { self.lock.unlock() }

        if let src = self.source {
            src.cancel()
            self.source = nil
        }

        if self.fileDescriptor != -1 {
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }
    }

    // MARK: - Monitoring

    private func indexInitialFiles() {
        self.lock.lock()
        defer { self.lock.unlock() }

        if let contents = try? FileManager.default.contentsOfDirectory(atPath: self.folderURL.path) {
            self.knownFiles = Set(contents)
        }
    }

    private func startObserving() {
        self.lock.lock()
        defer { self.lock.unlock() }

        let fd = open(self.folderURL.path, O_EVTONLY)
        guard fd >= 0 else { return }
        self.fileDescriptor = fd

        let dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .attrib],
            queue: DispatchQueue.global(qos: .utility)
        )

        dispatchSource.setEventHandler { [weak self] in
            self?.scanForNewFiles()
        }

        dispatchSource.setCancelHandler {
            close(fd)
        }

        self.source = dispatchSource
        dispatchSource.resume()
    }

    private func scanForNewFiles() {
        self.lock.lock()
        let currentContents = (try? FileManager.default.contentsOfDirectory(atPath: self.folderURL.path)) ?? []
        let previousSet = self.knownFiles
        let newFileNames = currentContents.filter { !previousSet.contains($0) }

        var newlyFoundURLs: [URL] = []
        for name in newFileNames {
            self.knownFiles.insert(name)
            let fileURL = self.folderURL.appendingPathComponent(name)
            let ext = fileURL.pathExtension.lowercased()
            if self.supportedExtensions.contains(ext) {
                newlyFoundURLs.append(fileURL)
            }
        }
        self.lock.unlock()

        if !newlyFoundURLs.isEmpty {
            self.onNewImages(newlyFoundURLs)
        }
    }
}
