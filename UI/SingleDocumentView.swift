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
    @ObservedObject private var shortcuts = KeyboardShortcutManager.shared

    public init(viewModel: SingleDocumentViewModel = SingleDocumentViewModel()) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            CanvasView(
                image: self.viewModel.previewImage,
                originalImage: self.viewModel.originalPreviewImage,
                metadata: self.viewModel.metadata,
                isLoading: self.viewModel.isRendering,
                isCropping: self.$viewModel.isCropping,
                isLoupeActive: self.$viewModel.isLoupeActive,
                onApplyCrop: { rect in
                    self.viewModel.applyCrop(normalizedRect: rect)
                }
            )

            // Multi-Page Floating Navigation Capsule
            if self.viewModel.pageCount > 1 {
                HStack(spacing: 10) {
                    Button(action: { self.viewModel.previousPage() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(self.viewModel.currentPageIndex == 0)
                    .help("Previous Page")

                    Menu {
                        ForEach(0..<self.viewModel.pageCount, id: \.self) { idx in
                            Button("Page \(idx + 1)") {
                                self.viewModel.selectPage(index: idx)
                            }
                        }
                    } label: {
                        Text("Page \(self.viewModel.currentPageIndex + 1) of \(self.viewModel.pageCount)")
                            .font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .foregroundColor(.primary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    Button(action: { self.viewModel.nextPage() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(self.viewModel.currentPageIndex >= self.viewModel.pageCount - 1)
                    .help("Next Page")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: self.viewModel.pageCount)
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
                filmProfile: self.$viewModel.filmProfile,
                blackPoint: self.$viewModel.blackPoint,
                gammaPoint: self.$viewModel.gammaPoint,
                whitePoint: self.$viewModel.whitePoint,
                sepia: self.$viewModel.sepia,
                negate: self.$viewModel.negate,
                denoise: self.$viewModel.denoise,
                isAutoTrimmed: self.$viewModel.isAutoTrimmed,
                trimFuzz: self.$viewModel.trimFuzz,
                sharpen: self.$viewModel.sharpen,
                blur: self.$viewModel.blur,
                watermarkText: self.$viewModel.watermarkText,
                watermarkFontSize: self.$viewModel.watermarkFontSize,
                watermarkOpacity: self.$viewModel.watermarkOpacity,
                watermarkPosition: self.$viewModel.watermarkPosition,
                stripMetadata: self.$viewModel.stripMetadata,
                targetFormat: self.$viewModel.targetFormat,
                quality: self.$viewModel.quality,
                targetColorspace: self.$viewModel.targetColorspace,
                bitDepth: self.$viewModel.bitDepth,
                quantizeColors: self.$viewModel.quantizeColors,
                borderWidth: self.$viewModel.borderWidth,
                borderHeight: self.$viewModel.borderHeight,
                borderColor: self.$viewModel.borderColor,
                isFrameEnabled: self.$viewModel.isFrameEnabled,
                frameWidth: self.$viewModel.frameWidth,
                frameHeight: self.$viewModel.frameHeight,
                frameColor: self.$viewModel.frameColor,
                oilPaintRadius: self.$viewModel.oilPaintRadius,
                charcoalRadius: self.$viewModel.charcoalRadius,
                sketchRadius: self.$viewModel.sketchRadius,
                embossRadius: self.$viewModel.embossRadius,
                edgeRadius: self.$viewModel.edgeRadius,
                noiseAmount: self.$viewModel.noiseAmount,
                noiseType: self.$viewModel.noiseType,
                isCropping: self.$viewModel.isCropping,
                histogramData: self.viewModel.histogramData,
                metadata: self.viewModel.metadata,
                originalWidth: self.viewModel.metadata?.width,
                originalHeight: self.viewModel.metadata?.height,
                isProcessing: self.viewModel.isRendering,
                onOptimizeTargetSize: { bytes in
                    Task { await self.viewModel.optimizeToTargetSize(targetBytes: bytes) }
                },
                onReset: { self.viewModel.resetParameters() },
                onExport: self.presentExportPanel
            )
            .inspectorColumnWidth(min: 280, ideal: 310, max: 360)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Open Image
                Button(action: self.presentOpenPanel) {
                    Label("Open Image", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut(
                    self.shortcuts.shortcut(for: .openImage).keyEquivalent,
                    modifiers: self.shortcuts.shortcut(for: .openImage).eventModifiers
                )
                .help("Open an image file (\(self.shortcuts.shortcut(for: .openImage).displayString))")

                // Export Image
                Button(action: self.presentExportPanel) {
                    Label("Export Image", systemImage: "square.and.arrow.up")
                }
                .keyboardShortcut(
                    self.shortcuts.shortcut(for: .exportImage).keyEquivalent,
                    modifiers: self.shortcuts.shortcut(for: .exportImage).eventModifiers
                )
                .disabled(self.viewModel.currentImageURL == nil)
                .help("Export processed image (\(self.shortcuts.shortcut(for: .exportImage).displayString))")

                // Undo
                Button(action: { self.viewModel.performUndo() }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .keyboardShortcut(
                    self.shortcuts.shortcut(for: .undo).keyEquivalent,
                    modifiers: self.shortcuts.shortcut(for: .undo).eventModifiers
                )
                .disabled(!self.viewModel.history.canUndo)
                .help("Undo last edit (\(self.shortcuts.shortcut(for: .undo).displayString))")

                // Redo
                Button(action: { self.viewModel.performRedo() }) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .keyboardShortcut(
                    self.shortcuts.shortcut(for: .redo).keyEquivalent,
                    modifiers: self.shortcuts.shortcut(for: .redo).eventModifiers
                )
                .disabled(!self.viewModel.history.canRedo)
                .help("Redo last edit (\(self.shortcuts.shortcut(for: .redo).displayString))")

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
                .keyboardShortcut(
                    self.shortcuts.shortcut(for: .toggleInspector).keyEquivalent,
                    modifiers: self.shortcuts.shortcut(for: .toggleInspector).eventModifiers
                )
                .help("Show or hide inspector (\(self.shortcuts.shortcut(for: .toggleInspector).displayString))")
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
        panel.allowedContentTypes = [.image, .pdf]

        if panel.runModal() == .OK, let selectedURL = panel.url {
            self.viewModel.loadNewImage(url: selectedURL)
        }
    }

    private func presentExportPanel() {
        guard let sourceURL = self.viewModel.currentImageURL else { return }

        let panel = NSSavePanel()
        let ext = self.viewModel.targetFormat.lowercased()
        let pageSuffix = (self.viewModel.pageCount > 1 && !self.viewModel.exportAllPages) ? "-p\(self.viewModel.currentPageIndex + 1)" : ""
        panel.nameFieldStringValue = "exported-\(sourceURL.deletingPathExtension().lastPathComponent)\(pageSuffix).\(ext)"

        if panel.runModal() == .OK, let destinationURL = panel.url {
            self.viewModel.isRendering = true
            Task {
                defer { self.viewModel.isRendering = false }
                do {
                    let ops: [any ImageOperation] = self.viewModel.buildPipelineOperations().map { $0 }
                    let pageIdx = (self.viewModel.pageCount > 1 && !self.viewModel.exportAllPages) ? self.viewModel.currentPageIndex : nil
                    _ = try await ImagePipeline.shared.export(
                        from: sourceURL,
                        pageIndex: pageIdx,
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
