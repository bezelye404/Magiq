//
//  SingleDocumentView.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - SingleDocumentView

/// Single image editing view with interactive canvas, native macOS inspector drawer, and export flow.
public struct SingleDocumentView: View {
    @State private var currentImageURL: URL?
    @State private var previewImage: NSImage?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showInspector: Bool = true

    // Inspector Operation States
    @State private var resizeWidth: Int = 1920
    @State private var resizeHeight: Int = 1080
    @State private var maintainAspectRatio: Bool = true
    @State private var rotationDegrees: Double = 0.0
    @State private var targetFormat: String = "WEBP"
    @State private var quality: Int = 85

    public init() {}

    public var body: some View {
        CanvasView(image: self.previewImage, isLoading: self.isLoading)
            .frame(minWidth: 480, maxWidth: .infinity, minHeight: 360, maxHeight: .infinity)
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                self.handleDrop(providers: providers)
            }
            .inspector(isPresented: self.$showInspector) {
                InspectorView(
                    resizeWidth: self.$resizeWidth,
                    resizeHeight: self.$resizeHeight,
                    maintainAspectRatio: self.$maintainAspectRatio,
                    rotationDegrees: self.$rotationDegrees,
                    targetFormat: self.$targetFormat,
                    quality: self.$quality,
                    isProcessing: self.isLoading,
                    onApply: { Task { await self.updatePreview() } },
                    onReset: self.resetParameters,
                    onExport: self.presentExportPanel
                )
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: self.presentOpenPanel) {
                        Label("Open Image", systemImage: "square.and.arrow.down")
                    }
                    .keyboardShortcut("o", modifiers: .command)
                    .help("Open an image file (⌘O)")

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

    // MARK: - Image Operations

    /// Updates live preview via the fast Linked Path.
    private func updatePreview() async {
        guard let url = self.currentImageURL else { return }

        self.isLoading = true
        defer { self.isLoading = false }

        do {
            var ops: [any ImageOperation] = []

            if self.resizeWidth > 0 && self.resizeHeight > 0 {
                ops.append(ResizeOperation(
                    width: self.resizeWidth,
                    height: self.resizeHeight,
                    maintainAspectRatio: self.maintainAspectRatio
                ))
            }

            if self.rotationDegrees != 0.0 {
                ops.append(RotateOperation(degrees: self.rotationDegrees))
            }

            ops.append(FormatConvertOperation(format: self.targetFormat, quality: self.quality))

            // Linked path: renders in RAM with bounded geometry
            let rendered = try await ImagePipeline.shared.generatePreview(
                from: url,
                boundedTo: MagickGeometry(width: 1200, height: 1200),
                operations: ops
            )
            self.previewImage = rendered
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func resetParameters() {
        self.rotationDegrees = 0.0
        self.quality = 85
        Task { await self.updatePreview() }
    }

    // MARK: - Open & Export Panels

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK, let selectedURL = panel.url {
            self.currentImageURL = selectedURL
            Task { await self.updatePreview() }
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
                    var ops: [any ImageOperation] = []
                    if self.resizeWidth > 0 && self.resizeHeight > 0 {
                        ops.append(ResizeOperation(
                            width: self.resizeWidth,
                            height: self.resizeHeight,
                            maintainAspectRatio: self.maintainAspectRatio
                        ))
                    }
                    if self.rotationDegrees != 0.0 {
                        ops.append(RotateOperation(degrees: self.rotationDegrees))
                    }
                    ops.append(FormatConvertOperation(format: self.targetFormat, quality: self.quality))

                    // CLI path: exports cleanly to destination URL
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

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            DispatchQueue.main.async {
                self.currentImageURL = url
                Task { await self.updatePreview() }
            }
        }
        return true
    }
}
