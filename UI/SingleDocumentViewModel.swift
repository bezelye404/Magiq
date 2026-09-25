//
//  SingleDocumentViewModel.swift
//  Magiq
//

import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - SingleDocumentViewModel

/// Long-lived view model managing the active single-document session.
/// Persists across navigation tab switches to prevent document data loss.
@MainActor
public final class SingleDocumentViewModel: ObservableObject {
    public let history = HistoryManager()

    // MARK: - Document State
    @Published public var currentImageURL: URL?
    @Published public var metadata: ImageMetadata?
    @Published public var previewImage: NSImage?
    @Published public var originalPreviewImage: NSImage?
    @Published public var isRendering: Bool = false
    @Published public var errorMessage: String?
    @Published public var showInspector: Bool = true

    // MARK: - Transformation Parameters
    @Published public var resizeWidth: Int = 1920 {
        didSet { self.onParameterChanged() }
    }
    @Published public var resizeHeight: Int = 1080 {
        didSet { self.onParameterChanged() }
    }
    @Published public var maintainAspectRatio: Bool = true
    @Published public var rotationDegrees: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var flipHorizontal: Bool = false {
        didSet { self.onParameterChanged() }
    }
    @Published public var flipVertical: Bool = false {
        didSet { self.onParameterChanged() }
    }
    @Published public var brightness: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var contrast: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var saturation: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var autoLevel: Bool = false {
        didSet { self.onParameterChanged() }
    }
    @Published public var sharpen: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var blur: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var stripMetadata: Bool = false {
        didSet { self.onParameterChanged() }
    }
    @Published public var targetFormat: String = "WEBP" {
        didSet { self.onParameterChanged() }
    }
    @Published public var quality: Int = 85 {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Private Task Management (RAM Protection)
    private var activeRenderTask: Task<Void, Never>?
    private var historyDebounceTask: Task<Void, Never>?
    private var isBatchUpdating: Bool = false

    public init() {}

    // MARK: - Real-Time Rendering & Task Cancellation

    private func onParameterChanged() {
        guard !self.isBatchUpdating, self.currentImageURL != nil else { return }
        self.scheduleLivePreview()
        self.scheduleHistoryRecord()
    }

    /// Cancels any in-flight render task and debounces by 45ms to protect RAM from slider flooding.
    public func scheduleLivePreview() {
        guard let url = self.currentImageURL else { return }

        // 1. Instantly abort previous work to prevent thread & RAM accumulation
        self.activeRenderTask?.cancel()

        let pipelineOps = self.buildPipelineOperations()
        let ops: [any ImageOperation] = pipelineOps.map { $0 }

        self.activeRenderTask = Task { [weak self] in
            // 45ms debounce window for smooth 60fps sliding without CPU thrashing
            try? await Task.sleep(nanoseconds: 45_000_000)
            guard !Task.isCancelled else { return }

            guard let self = self else { return }
            self.isRendering = true
            defer { self.isRendering = false }

            do {
                let rendered = try await ImagePipeline.shared.generatePreview(
                    from: url,
                    boundedTo: MagickGeometry(width: 1400, height: 1400),
                    operations: ops
                )

                guard !Task.isCancelled else { return }
                self.previewImage = rendered
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func scheduleHistoryRecord() {
        self.historyDebounceTask?.cancel()
        let currentOps = self.buildPipelineOperations()

        self.historyDebounceTask = Task { [weak self] in
            // Wait 500ms after user stops moving sliders before committing a history snapshot
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.history.push(stepName: "Adjustment", operations: currentOps)
        }
    }

    // MARK: - Document Loading

    public func loadNewImage(url: URL) {
        self.currentImageURL = url
        self.activeRenderTask?.cancel()
        self.historyDebounceTask?.cancel()

        Task {
            do {
                // Ping header to read natural dimensions without buffer decode
                let meta = try ImageWand.pingMetadata(from: url)
                self.metadata = meta

                self.isBatchUpdating = true
                self.resizeWidth = meta.width
                self.resizeHeight = meta.height
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
                self.isBatchUpdating = false

                // Load initial clean preview
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

    // MARK: - Undo & Redo

    public func performUndo() {
        guard let state = self.history.undo() else { return }
        self.applyPipelineOperations(state)
    }

    public func performRedo() {
        guard let state = self.history.redo() else { return }
        self.applyPipelineOperations(state)
    }

    public func applyPipelineOperations(_ operations: [PipelineOperation]) {
        self.isBatchUpdating = true

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

        self.isBatchUpdating = false
        self.scheduleLivePreview()
    }

    public func applyPreset(_ preset: Preset) {
        self.targetFormat = preset.outputFormat
        self.quality = preset.quality
        self.stripMetadata = preset.stripMetadata
        self.applyPipelineOperations(preset.operations)
        self.history.push(stepName: "Preset: \(preset.name)", operations: self.buildPipelineOperations())
    }

    public func resetParameters() {
        self.isBatchUpdating = true
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
        self.isBatchUpdating = false

        self.scheduleLivePreview()
        self.history.push(stepName: "Reset Parameters", operations: self.buildPipelineOperations())
    }

    // MARK: - Pipeline Builder

    public func buildPipelineOperations() -> [PipelineOperation] {
        var ops: [PipelineOperation] = []

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

        if self.flipHorizontal || self.flipVertical {
            ops.append(.flipFlop(FlipFlopOperation(
                horizontal: self.flipHorizontal,
                vertical: self.flipVertical
            )))
        }

        if self.rotationDegrees != 0.0 {
            ops.append(.rotate(RotateOperation(degrees: self.rotationDegrees)))
        }

        if self.brightness != 0.0 || self.contrast != 0.0 || self.saturation != 0.0 {
            ops.append(.colorAdjust(ColorAdjustOperation(
                brightness: self.brightness,
                contrast: self.contrast,
                saturation: self.saturation
            )))
        }

        if self.autoLevel {
            ops.append(.autoLevel(AutoLevelOperation(enabled: true)))
        }

        if self.sharpen > 0.0 || self.blur > 0.0 {
            ops.append(.sharpenBlur(SharpenBlurOperation(
                sharpen: self.sharpen,
                blur: self.blur
            )))
        }

        if self.stripMetadata {
            ops.append(.stripMetadata(StripMetadataOperation(enabled: true)))
        }

        ops.append(.formatConvert(FormatConvertOperation(format: self.targetFormat, quality: self.quality)))
        return ops
    }
}
