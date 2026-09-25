//
//  BatchQueueView.swift
//  Magiq
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - BatchQueueView

public struct BatchQueueView: View {
    @ObservedObject private var queue = BatchQueueManager.shared
    @ObservedObject private var presets = PresetStore.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Top Action Toolbar
            self.toolbarHeader

            Divider()

            // Statistics bar (if items exist)
            if self.queue.totalCount > 0 {
                self.statisticsBar
                Divider()
            }

            // Main Content: Empty State or Table
            if self.queue.items.isEmpty {
                self.emptyDropZone
            } else {
                self.itemsTable
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            self.handleDrop(providers: providers)
        }
    }

    // MARK: - Subviews

    private var toolbarHeader: some View {
        HStack(spacing: 12) {
            // Add Files
            Button(action: self.presentAddFilesPanel) {
                Label("Add Files...", systemImage: "photo.badge.plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            // Add Folder
            Button(action: self.presentAddFolderPanel) {
                Label("Add Folder...", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            // Watch Folder
            Button(action: self.toggleWatchFolder) {
                HStack(spacing: 4) {
                    Image(systemName: self.queue.isWatchingFolder ? "eye.fill" : "eye")
                        .foregroundStyle(self.queue.isWatchingFolder ? Color.green : Color.primary)
                    Text(self.queue.isWatchingFolder ? "Watching" : "Watch Folder")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(self.queue.isWatchingFolder ? "Watching: \(self.queue.watchedFolderURL?.lastPathComponent ?? "")" : "Auto-process new images added to a folder")

            Divider().frame(height: 18)

            // Preset Selector Menu
            Menu {
                ForEach(self.presets.presets) { preset in
                    Button(action: { self.queue.selectedPreset = preset }) {
                        Label(preset.name, systemImage: preset.iconName)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: self.queue.selectedPreset?.iconName ?? "slider.horizontal.3")
                        .foregroundStyle(.tint)
                    Text(self.queue.selectedPreset?.name ?? "Select Preset")
                        .fontWeight(.medium)
                }
                .frame(minWidth: 160, alignment: .leading)
            }
            .menuStyle(.borderedButton)
            .controlSize(.regular)

            Spacer()

            // Clear Completed
            if self.queue.completedCount > 0 {
                Button("Clear Completed") {
                    self.queue.clearCompleted()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            // Start / Cancel Button
            if self.queue.isProcessing {
                Button(action: { self.queue.cancelProcessing() }) {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.regular)
            } else {
                Button(action: { self.queue.startProcessing() }) {
                    Label("Start Batch", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(self.queue.pendingCount == 0 || self.queue.selectedPreset == nil)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var statisticsBar: some View {
        VStack(spacing: 6) {
            ProgressView(value: self.queue.overallProgress)
                .progressViewStyle(.linear)

            HStack {
                Text("\(self.queue.completedCount) of \(self.queue.totalCount) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if self.queue.totalBytesSaved > 0 {
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("\(self.queue.totalBytesSavedFormatted) saved")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }

                if self.queue.failedCount > 0 {
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("\(self.queue.failedCount) failed")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }

                Spacer()

                Text("\(UserSettings.shared.workerCount) workers active")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }

    private var emptyDropZone: some View {
        VStack(spacing: DesignTokens.spacingMedium) {
            Image(systemName: "square.stack.3d.down.right")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tint)

            VStack(spacing: 4) {
                Text("Batch Queue is Empty")
                    .font(.title3.bold())

                Text("Drag and drop images or entire folders here to process them with bounded memory workers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            HStack(spacing: 12) {
                Button(action: self.presentAddFilesPanel) {
                    Label("Choose Files", systemImage: "photo")
                }
                .buttonStyle(.bordered)

                Button(action: self.presentAddFolderPanel) {
                    Label("Choose Folder", systemImage: "folder")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemsTable: some View {
        List {
            ForEach(self.queue.items) { item in
                self.itemRow(item)
                    .padding(.vertical, 2)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    private func itemRow(_ item: BatchItem) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "photo")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)

            // File Name & Path
            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(item.sourceURL.deletingLastPathComponent().path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Status Details
            switch item.status {
            case .pending:
                Text(item.originalSizeFormatted)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Text("Queued")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15), in: Capsule())

            case .processing:
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 20, height: 20)

                Text("Processing...")
                    .font(.caption2.bold())
                    .foregroundStyle(.tint)

            case .completed(let outputURL, let outputSize, let duration):
                HStack(spacing: 8) {
                    Text("\(item.originalSizeFormatted) → \(item.formattedOutputSize(bytes: outputSize))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if let savings = item.sizeSavingsFormatted(outputBytes: outputSize) {
                        Text(savings)
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12), in: Capsule())
                    }

                    Text(String(format: "%.1fs", duration))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)

                    Button(action: { NSWorkspace.shared.activateFileViewerSelecting([outputURL]) }) {
                        Image(systemName: "folder")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")
                }

            case .failed(let errorDesc):
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorDesc)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }

            case .cancelled:
                Text("Cancelled")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Remove button
            if !self.queue.isProcessing {
                Button(action: { self.queue.removeItem(id: item.id) }) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Remove from queue")
            }
        }
    }

    // MARK: - File Panels

    private func presentAddFilesPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK {
            self.queue.addFiles(urls: panel.urls)
        }
    }

    private func presentAddFolderPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let folder = panel.url {
            self.queue.addFolder(url: folder)
        }
    }

    private func toggleWatchFolder() {
        if self.queue.isWatchingFolder {
            self.queue.stopWatching()
        } else {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.message = "Choose a folder to observe for incoming images"

            if panel.runModal() == .OK, let folder = panel.url {
                self.queue.startWatching(folder: folder)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                DispatchQueue.main.async {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                        self.queue.addFolder(url: url)
                    } else {
                        self.queue.addFiles(urls: [url])
                    }
                }
            }
        }
        return true
    }
}
