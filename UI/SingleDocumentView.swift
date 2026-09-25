//
//  SingleDocumentView.swift
//  Magiq
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - SingleDocumentView

public struct SingleDocumentView: View {
    @StateObject private var history = HistoryManager()

    @State private var currentImageURL: URL?
    @State private var metadata: ImageMetadata?
    @State private var previewImage: NSImage?
    @State private var originalPreviewImage: NSImage?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showInspector: Bool = true

    // Operation Parameters
    @State private var resizeWidth: Int = 1920
    @State private var resizeHeight: Int = 1080
    @State private var maintainAspectRatio: Bool = true
    @State private var rotationDegrees: Double = 0.0
    @State private var flipHorizontal: Bool = false
    @State private var flipVertical: Bool = false
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 0.0
    @State private var saturation: Double = 0.0
    @State private var autoLevel: Bool = false
    @State private var sharpen: Double = 0.0
    @State private var blur: Double = 0.0
    @State private var stripMetadata: Bool = false
    @State private var targetFormat: String = "WEBP"
    @State private var quality: Int = 85

    public init() {}

    public var body: some View {
        CanvasView(
            image: self.previewImage,
            originalImage: self.originalPreviewImage,
            metadata: self.metadata,
            isLoading: self.isLoading
        )
        .frame(minWidth: 150, maxWidth: .infinity, minHeight: 150, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            self.handleDrop(providers: providers)
        }
        .inspector(isPresented: self.$showInspector) {
            InspectorView(
                resizeWidth: self.$resizeWidth,
                resizeHeight: self.$resizeHeight,
                maintainAspectRatio: self.$maintainAspectRatio,
                rotationDegrees: self.$rotationDegrees,
                flipHorizontal: self.$flipHorizontal,
                flipVertical: self.$flipVertical,
                brightness: self.$brightness,
                contrast: self.$contrast,
                saturation: self.$saturation,
                autoLevel: self.$autoLevel,
                sharpen: self.$sharpen,
                blur: self.$blur,
                stripMetadata: self.$stripMetadata,
                targetFormat: self.$targetFormat,
                quality: self.$quality,
                originalWidth: self.metadata?.width,
                originalHeight: self.metadata?.height,
                isProcessing: self.isLoading,
                onApply: { Task { await self.updatePreview(recordHistory: true) } },
                onReset: self.resetParameters,
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
                Button(action: self.performUndo) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!self.history.canUndo)
                .help("Undo last edit (⌘Z)")

                // Redo
                Button(action: self.performRedo) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!self.history.canRedo)
                .help("Redo last edit (⇧⌘Z)")

                // Presets Menu
                Menu {
                    ForEach(PresetStore.shared.presets) { preset in
                        Button(action: { self.applyPreset(preset) }) {
                            Label(preset.name, systemImage: preset.iconName)
                        }
                    }
                } label: {
                    Label("Apply Preset", systemImage: "sparkles")
                }
                .help("Apply a recipe preset to this image")

                // Inspector Toggle
                Button(action: { self.showInspector.toggle() }) {
                    Label("Toggle Inspector", systemImage: "sidebar.trailing")
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
                .help("Show or hide inspector (⌥⌘I)")
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { self.errorMessage != nil },
                set: { if !$0 { self.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(self.errorMessage ?? "An unknown error occurred.") }
        )
    }

    // MARK: - Operations & Live Preview

    private func buildPipelineOperations() -> [PipelineOperation] {
        var ops: [PipelineOperation] = []

        // Resize
        if self.resizeWidth > 0 && self.resizeHeight > 0 {
            if let meta = self.metadata {
                if meta.width != self.resizeWidth || meta.height != self.resizeHeight {
                    ops.append(.resize(ResizeOperation(
                        width: self.resizeWidth,
                        height: self.resizeHeight,
                        maintainAspectRatio: self.maintainAspectRatio
                    )))
                }
            } else {
                ops.append(.resize(ResizeOperation(
                    width: self.resizeWidth,
                    height: self.resizeHeight,
                    maintainAspectRatio: self.maintainAspectRatio
                )))
            }
        }

        // Flip & Flop
        if self.flipHorizontal || self.flipVertical {
            ops.append(.flipFlop(FlipFlopOperation(
                horizontal: self.flipHorizontal,
                vertical: self.flipVertical
            )))
        }

        // Rotate
        if self.rotationDegrees != 0.0 {
            ops.append(.rotate(RotateOperation(degrees: self.rotationDegrees)))
        }

        // Color & Tone
        if self.brightness != 0.0 || self.contrast != 0.0 || self.saturation != 0.0 {
            ops.append(.colorAdjust(ColorAdjustOperation(
                brightness: self.brightness,
                contrast: self.contrast,
                saturation: self.saturation
            )))
        }

        // Auto Level
        if self.autoLevel {
            ops.append(.autoLevel(AutoLevelOperation(enabled: true)))
        }

        // Sharpen & Blur
        if self.sharpen > 0.0 || self.blur > 0.0 {
            ops.append(.sharpenBlur(SharpenBlurOperation(
                sharpen: self.sharpen,
                blur: self.blur
            )))
        }

        // Strip Metadata
        if self.stripMetadata {
            ops.append(.stripMetadata(StripMetadataOperation(enabled: true)))
        }

        // Format & Quality
        ops.append(.formatConvert(FormatConvertOperation(format: self.targetFormat, quality: self.quality)))

        return ops
    }

    private func updatePreview(recordHistory: Bool = false) async {
        guard let url = self.currentImageURL else { return }

        self.isLoading = true
        defer { self.isLoading = false }

        do {
            let pipelineOps = self.buildPipelineOperations()
            if recordHistory {
                self.history.push(stepName: "Image Edit", operations: pipelineOps)
            }

            let ops: [any ImageOperation] = pipelineOps.map { $0 }
            let rendered = try await ImagePipeline.shared.generatePreview(
                from: url,
                boundedTo: MagickGeometry(width: 1400, height: 1400),
                operations: ops
            )
            self.previewImage = rendered
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func loadNewImage(url: URL) {
        self.currentImageURL = url
        self.isLoading = true

        Task {
            defer { self.isLoading = false }
            do {
                // Ping header to read natural dimensions without buffer decode
                let meta = try ImageWand.pingMetadata(from: url)
                self.metadata = meta
                self.resizeWidth = meta.width
                self.resizeHeight = meta.height

                // Reset transformations to clean baseline
                self.rotationDegrees = 0.0
                self.flipHorizontal = false
                self.flipVertical = false
                self.brightness = 0.0
                self.contrast = 0.0
                self.saturation = 0.0
                self.autoLevel = false
                self.sharpen = 0.0
                self.blur = 0.0
                self.stripMetadata = false
                self.quality = 85

                // Load initial clean preview for split compare
                let basePreview = try await ImagePipeline.shared.generatePreview(
                    from: url,
                    boundedTo: MagickGeometry(width: 1400, height: 1400),
                    operations: []
                )
                self.originalPreviewImage = basePreview
                self.previewImage = basePreview

                self.history.reset(initialOperations: self.buildPipelineOperations())
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func resetParameters() {
        if let meta = self.metadata {
            self.resizeWidth = meta.width
            self.resizeHeight = meta.height
        }
        self.rotationDegrees = 0.0
        self.flipHorizontal = false
        self.flipVertical = false
        self.brightness = 0.0
        self.contrast = 0.0
        self.saturation = 0.0
        self.autoLevel = false
        self.sharpen = 0.0
        self.blur = 0.0
        self.stripMetadata = false
        self.quality = 85

        Task { await self.updatePreview(recordHistory: true) }
    }

    // MARK: - Undo & Redo

    private func performUndo() {
        guard let state = self.history.undo() else { return }
        self.applyPipelineOperations(state)
    }

    private func performRedo() {
        guard let state = self.history.redo() else { return }
        self.applyPipelineOperations(state)
    }

    private func applyPipelineOperations(_ operations: [PipelineOperation]) {
        // Reset local flags first
        self.rotationDegrees = 0.0
        self.flipHorizontal = false
        self.flipVertical = false
        self.brightness = 0.0
        self.contrast = 0.0
        self.saturation = 0.0
        self.autoLevel = false
        self.sharpen = 0.0
        self.blur = 0.0
        self.stripMetadata = false

        for op in operations {
            switch op {
            case .resize(let resize):
                self.resizeWidth = resize.width
                self.resizeHeight = resize.height
                self.maintainAspectRatio = resize.maintainAspectRatio
            case .flipFlop(let flip):
                self.flipHorizontal = flip.horizontal
                self.flipVertical = flip.vertical
            case .rotate(let rot):
                self.rotationDegrees = rot.degrees
            case .colorAdjust(let col):
                self.brightness = col.brightness
                self.contrast = col.contrast
                self.saturation = col.saturation
            case .autoLevel(let auto):
                self.autoLevel = auto.enabled
            case .sharpenBlur(let sharp):
                self.sharpen = sharp.sharpen
                self.blur = sharp.blur
            case .stripMetadata(let strip):
                self.stripMetadata = strip.enabled
            case .formatConvert(let fmt):
                self.targetFormat = fmt.format
                self.quality = fmt.quality
            case .crop:
                break
            }
        }

        Task { await self.updatePreview(recordHistory: false) }
    }

    private func applyPreset(_ preset: Preset) {
        self.targetFormat = preset.outputFormat
        self.quality = preset.quality
        self.stripMetadata = preset.stripMetadata
        self.applyPipelineOperations(preset.operations)
        self.history.push(stepName: "Apply Preset (\(preset.name))", operations: self.buildPipelineOperations())
    }

    // MARK: - File Panels

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK, let selectedURL = panel.url {
            self.loadNewImage(url: selectedURL)
        }
    }

    private func presentExportPanel() {
        guard let sourceURL = self.currentImageURL else { return }

        let panel = NSSavePanel()
        let ext = self.targetFormat.lowercased()
        panel.nameFieldStringValue = "exported-\(sourceURL.deletingPathExtension().lastPathComponent).\(ext)"

        if panel.runModal() == .OK, let destinationURL = panel.url {
            self.isLoading = true
            Task {
                defer { self.isLoading = false }
                do {
                    let ops: [any ImageOperation] = self.buildPipelineOperations().map { $0 }
                    _ = try await ImagePipeline.shared.export(
                        from: sourceURL,
                        to: destinationURL,
                        operations: ops
                    )
                } catch {
                    self.errorMessage = error.localizedDescription
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
                self.loadNewImage(url: url)
            }
        }
        return true
    }
}
