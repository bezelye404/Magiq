//
//  SingleDocumentView.swift
//  Magiq
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - SingleDocumentView

public struct SingleDocumentView: View {
    @ObservedObject public var viewModel: SingleDocumentViewModel

    public init(viewModel: SingleDocumentViewModel = SingleDocumentViewModel()) {
        self.viewModel = viewModel
    }

    public var body: some View {
        CanvasView(
            image: self.viewModel.previewImage,
            originalImage: self.viewModel.originalPreviewImage,
            metadata: self.viewModel.metadata,
            isLoading: self.viewModel.isRendering
        )
        .frame(minWidth: 150, maxWidth: .infinity, minHeight: 150, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            self.handleDrop(providers: providers)
        }
        .inspector(isPresented: self.$viewModel.showInspector) {
            InspectorView(
                resizeWidth: self.$viewModel.resizeWidth,
                resizeHeight: self.$viewModel.resizeHeight,
                maintainAspectRatio: self.$viewModel.maintainAspectRatio,
                rotationDegrees: self.$viewModel.rotationDegrees,
                flipHorizontal: self.$viewModel.flipHorizontal,
                flipVertical: self.$viewModel.flipVertical,
                brightness: self.$viewModel.brightness,
                contrast: self.$viewModel.contrast,
                saturation: self.$viewModel.saturation,
                autoLevel: self.$viewModel.autoLevel,
                sharpen: self.$viewModel.sharpen,
                blur: self.$viewModel.blur,
                stripMetadata: self.$viewModel.stripMetadata,
                targetFormat: self.$viewModel.targetFormat,
                quality: self.$viewModel.quality,
                originalWidth: self.viewModel.metadata?.width,
                originalHeight: self.viewModel.metadata?.height,
                isProcessing: self.viewModel.isRendering,
                onReset: { self.viewModel.resetParameters() },
                onExport: self.presentExportPanel
            )
            .inspectorColumnWidth(min: 280, ideal: 300, max: 350)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: self.presentOpenPanel) {
                    Label("Open Image", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("o", modifiers: .command)
                .help("Open an image file (⌘O)")

                // Undo
                Button(action: { self.viewModel.performUndo() }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!self.viewModel.history.canUndo)
                .help("Undo last edit (⌘Z)")

                // Redo
                Button(action: { self.viewModel.performRedo() }) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!self.viewModel.history.canRedo)
                .help("Redo last edit (⇧⌘Z)")

                // Presets Menu
                Menu {
                    ForEach(PresetStore.shared.presets) { preset in
                        Button(action: { self.viewModel.applyPreset(preset) }) {
                            Label(preset.name, systemImage: preset.iconName)
                        }
                    }
                } label: {
                    Label("Apply Preset", systemImage: "sparkles")
                }
                .help("Apply a recipe preset to this image")

                // Inspector Toggle
                Button(action: { self.viewModel.showInspector.toggle() }) {
                    Label("Toggle Inspector", systemImage: "sidebar.trailing")
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
                .help("Show or hide inspector (⌥⌘I)")
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { self.viewModel.errorMessage != nil },
                set: { if !$0 { self.viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(self.viewModel.errorMessage ?? "An unknown error occurred.") }
        )
    }

    // MARK: - File Panels

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK, let selectedURL = panel.url {
            self.viewModel.loadNewImage(url: selectedURL)
        }
    }

    private func presentExportPanel() {
        guard let sourceURL = self.viewModel.currentImageURL else { return }

        let panel = NSSavePanel()
        let ext = self.viewModel.targetFormat.lowercased()
        panel.nameFieldStringValue = "exported-\(sourceURL.deletingPathExtension().lastPathComponent).\(ext)"

        if panel.runModal() == .OK, let destinationURL = panel.url {
            self.viewModel.isRendering = true
            Task {
                defer { self.viewModel.isRendering = false }
                do {
                    let ops: [any ImageOperation] = self.viewModel.buildPipelineOperations().map { $0 }
                    _ = try await ImagePipeline.shared.export(
                        from: sourceURL,
                        to: destinationURL,
                        operations: ops
                    )
                } catch {
                    self.viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Drag & Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            DispatchQueue.main.async {
                self.viewModel.loadNewImage(url: url)
            }
        }
        return true
    }
}
