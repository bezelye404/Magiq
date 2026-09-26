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
    @Published public var histogramData: HistogramData?

    // MARK: - Multi-Page & Multi-Frame Document State
    @Published public var pageCount: Int = 1
    @Published public var currentPageIndex: Int = 0
    @Published public var exportAllPages: Bool = false

    // MARK: - Crop & Loupe States
    @Published public var isCropping: Bool = false
    @Published public var cropOperation: CropOperation? = nil {
        didSet { self.onParameterChanged() }
    }
    @Published public var isLoupeActive: Bool = false

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

    // MARK: - Color, Tone & Film Simulation
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
    @Published public var filmProfile: FilmProfile = .none {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Histogram Levels & Gamma
    @Published public var blackPoint: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var gammaPoint: Double = 1.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var whitePoint: Double = 255.0 {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Artistic Tone & Special Effects
    @Published public var sepia: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var negate: Bool = false {
        didSet { self.onParameterChanged() }
    }
    @Published public var denoise: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Auto-Trim
    @Published public var isAutoTrimmed: Bool = false {
        didSet { self.onParameterChanged() }
    }
    @Published public var trimFuzz: Double = 5.0 {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Border & Framing (Paket B)
    @Published public var borderWidth: Int = 0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var borderHeight: Int = 0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var borderColor: String = "black" {
        didSet { self.onParameterChanged() }
    }
    @Published public var isFrameEnabled: Bool = false {
        didSet { self.onParameterChanged() }
    }
    @Published public var frameWidth: Int = 15 {
        didSet { self.onParameterChanged() }
    }
    @Published public var frameHeight: Int = 15 {
        didSet { self.onParameterChanged() }
    }
    @Published public var frameColor: String = "#808080" {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Artistic & Stylize Filters (Paket C)
    @Published public var oilPaintRadius: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var charcoalRadius: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var sketchRadius: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var embossRadius: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var edgeRadius: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var noiseAmount: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var noiseType: MagiqNoiseType = .gaussian {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Sharpness & Blur
    @Published public var sharpen: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }
    @Published public var blur: Double = 0.0 {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Watermark & Text Annotation
    @Published public var watermarkText: String = "" {
        didSet { self.onParameterChanged() }
    }
    @Published public var watermarkFontSize: Int = 28 {
        didSet { self.onParameterChanged() }
    }
    @Published public var watermarkOpacity: Double = 0.7 {
        didSet { self.onParameterChanged() }
    }
    @Published public var watermarkPosition: WatermarkPosition = .bottomRight {
        didSet { self.onParameterChanged() }
    }
    @Published public var watermarkColor: String = "white" {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Export Settings
    @Published public var stripMetadata: Bool = false {
        didSet { self.onParameterChanged() }
    }
    @Published public var targetFormat: String = "WEBP" {
        didSet { self.onParameterChanged() }
    }
    @Published public var quality: Int = 85 {
        didSet { self.onParameterChanged() }
    }

    // MARK: - Colorspace, Depth & Palette Quantization
    @Published public var targetColorspace: String = "sRGB" {
        didSet { self.onParameterChanged() }
    }
    @Published public var bitDepth: Int = 8 {
        didSet { self.onParameterChanged() }
    }
    @Published public var quantizeColors: Int = 0 {
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

    /// Cancels in-flight render tasks and debounces by 45ms to protect RAM from slider thrashing.
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
                    pageIndex: self.currentPageIndex,
                    boundedTo: MagickGeometry(width: 1400, height: 1400),
                    operations: ops
                )

                guard !Task.isCancelled else { return }
                self.previewImage = rendered
                self.histogramData = HistogramData.calculate(from: rendered)
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Multi-Page Navigation

    public func selectPage(index: Int) {
        guard index >= 0, index < self.pageCount, index != self.currentPageIndex else { return }
        self.currentPageIndex = index

        // Also refresh original clean preview for comparison slider on current page
        if let url = self.currentImageURL {
            Task {
                if let base = try? await ImagePipeline.shared.generatePreview(
                    from: url,
                    pageIndex: index,
                    boundedTo: MagickGeometry(width: 1400, height: 1400),
                    operations: []
                ) {
                    self.originalPreviewImage = base
                }
            }
        }
        self.scheduleLivePreview()
    }

    public func nextPage() {
        if self.currentPageIndex < self.pageCount - 1 {
            self.selectPage(index: self.currentPageIndex + 1)
        }
    }

    public func previousPage() {
        if self.currentPageIndex > 0 {
            self.selectPage(index: self.currentPageIndex - 1)
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

                let pages = ImageWand.pingPageCount(from: url)
                self.pageCount = max(1, pages)
                self.currentPageIndex = 0

                self.isBatchUpdating = true
                self.cropOperation = nil
                self.isCropping = false
                self.resizeWidth = meta.width
                self.resizeHeight = meta.height
                self.rotationDegrees = 0.0
                self.flipHorizontal = false
                self.flipVertical = false
                self.brightness = 0.0
                self.contrast = 0.0
                self.saturation = 0.0
                self.autoLevel = false
                self.filmProfile = .none
                self.sharpen = 0.0
                self.blur = 0.0
                self.watermarkText = ""
                self.stripMetadata = false
                self.quality = 85
                self.targetColorspace = "sRGB"
                self.bitDepth = 8
                self.quantizeColors = 0
                self.borderWidth = 0
                self.borderHeight = 0
                self.borderColor = "black"
                self.isFrameEnabled = false
                self.frameWidth = 15
                self.frameHeight = 15
                self.frameColor = "#808080"
                self.oilPaintRadius = 0.0
                self.charcoalRadius = 0.0
                self.sketchRadius = 0.0
                self.embossRadius = 0.0
                self.edgeRadius = 0.0
                self.noiseAmount = 0.0
                self.noiseType = .gaussian
                self.isBatchUpdating = false

                // Load initial clean preview
                let basePreview = try await ImagePipeline.shared.generatePreview(
                    from: url,
                    pageIndex: 0,
                    boundedTo: MagickGeometry(width: 1400, height: 1400),
                    operations: []
                )
                self.originalPreviewImage = basePreview
                self.previewImage = basePreview
                self.histogramData = HistogramData.calculate(from: basePreview)

                self.history.reset(initialOperations: self.buildPipelineOperations())
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Crop Actions

    public func applyCrop(normalizedRect: CGRect) {
        guard let meta = self.metadata else { return }

        let pxX = Int(normalizedRect.minX * CGFloat(meta.width))
        let pxY = Int(normalizedRect.minY * CGFloat(meta.height))
        let pxW = max(10, Int(normalizedRect.width * CGFloat(meta.width)))
        let pxH = max(10, Int(normalizedRect.height * CGFloat(meta.height)))

        self.cropOperation = CropOperation(x: pxX, y: pxY, width: pxW, height: pxH)
        self.isCropping = false
        self.resizeWidth = pxW
        self.resizeHeight = pxH
        self.history.push(stepName: "Crop (\(pxW)x\(pxH))", operations: self.buildPipelineOperations())
    }

    // MARK: - Target Size Optimization

    public func optimizeToTargetSize(targetBytes: Int) async {
        guard let url = self.currentImageURL else { return }

        self.isRendering = true
        defer { self.isRendering = false }

        do {
            let ops = self.buildPipelineOperations().map { $0 }
            let result = try await TargetSizeOptimizer.findOptimalQuality(
                for: url,
                format: self.targetFormat,
                targetSizeBytes: targetBytes,
                operations: ops
            )
            self.quality = result.optimalQuality
        } catch {
            self.errorMessage = "Optimization failed: \(error.localizedDescription)"
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

        self.cropOperation = nil
        self.rotationDegrees = 0.0
        self.flipHorizontal = false
        self.flipVertical = false
        self.brightness = 0.0
        self.contrast = 0.0
        self.saturation = 0.0
        self.autoLevel = false
        self.filmProfile = .none
        self.blackPoint = 0.0
        self.gammaPoint = 1.0
        self.whitePoint = 255.0
        self.sepia = 0.0
        self.negate = false
        self.denoise = 0.0
        self.isAutoTrimmed = false
        self.trimFuzz = 5.0
        self.sharpen = 0.0
        self.blur = 0.0
        self.watermarkText = ""
        self.stripMetadata = false

        for op in operations {
            switch op {
            case .crop(let crop):
                self.cropOperation = crop
                self.resizeWidth = crop.width
                self.resizeHeight = crop.height
            case .trim(let trim):
                self.isAutoTrimmed = true
                self.trimFuzz = trim.fuzzPercent
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
            case .levels(let lev):
                self.blackPoint = lev.blackPoint
                self.gammaPoint = lev.gamma
                self.whitePoint = lev.whitePoint
            case .artisticTone(let tone):
                self.sepia = tone.sepia
                self.negate = tone.negate
                self.denoise = tone.denoise
            case .colorGrade(let grade):
                self.filmProfile = grade.profile
            case .sharpenBlur(let sharp):
                self.sharpen = sharp.sharpen
                self.blur = sharp.blur
            case .watermark(let wm):
                self.watermarkText = wm.text
                self.watermarkFontSize = wm.fontSize
                self.watermarkOpacity = wm.opacity
                self.watermarkPosition = wm.position
                self.watermarkColor = wm.color
            case .stripMetadata(let strip):
                self.stripMetadata = strip.enabled
            case .formatConvert(let fmt):
                self.targetFormat = fmt.format
                self.quality = fmt.quality
            case .colorspace(let cs):
                self.targetColorspace = cs.colorspace
            case .bitDepth(let bd):
                self.bitDepth = bd.depth
            case .quantize(let q):
                self.quantizeColors = q.numberColors
            case .border(let b):
                self.borderWidth = b.width
                self.borderHeight = b.height
                self.borderColor = b.color
            case .frame(let f):
                self.isFrameEnabled = true
                self.frameWidth = f.width
                self.frameHeight = f.height
                self.frameColor = f.color
            case .oilPaint(let op):
                self.oilPaintRadius = op.radius
            case .charcoal(let op):
                self.charcoalRadius = op.radius
            case .sketch(let op):
                self.sketchRadius = op.radius
            case .emboss(let op):
                self.embossRadius = op.radius
            case .edge(let op):
                self.edgeRadius = op.radius
            case .addNoise(let op):
                self.noiseAmount = op.attenuate
                self.noiseType = op.noiseType
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
        self.cropOperation = nil
        self.isCropping = false
        self.isAutoTrimmed = false
        self.trimFuzz = 5.0
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
        self.blackPoint = 0.0
        self.gammaPoint = 1.0
        self.whitePoint = 255.0
        self.sepia = 0.0
        self.negate = false
        self.denoise = 0.0
        self.filmProfile = .none
        self.sharpen = 0.0
        self.blur = 0.0
        self.watermarkText = ""
        self.stripMetadata = false
        self.quality = 85
        self.targetColorspace = "sRGB"
        self.bitDepth = 8
        self.quantizeColors = 0
        self.borderWidth = 0
        self.borderHeight = 0
        self.borderColor = "black"
        self.isFrameEnabled = false
        self.frameWidth = 15
        self.frameHeight = 15
        self.frameColor = "#808080"
        self.oilPaintRadius = 0.0
        self.charcoalRadius = 0.0
        self.sketchRadius = 0.0
        self.embossRadius = 0.0
        self.edgeRadius = 0.0
        self.noiseAmount = 0.0
        self.noiseType = .gaussian
        self.isBatchUpdating = false

        self.scheduleLivePreview()
        self.history.push(stepName: "Reset Parameters", operations: self.buildPipelineOperations())
    }

    // MARK: - Pipeline Builder

    public func buildPipelineOperations() -> [PipelineOperation] {
        var ops: [PipelineOperation] = []

        // 1. Auto-Trim (applied early on raw canvas)
        if self.isAutoTrimmed {
            ops.append(.trim(TrimOperation(fuzzPercent: self.trimFuzz)))
        }

        // 2. Crop
        if let crop = self.cropOperation {
            ops.append(.crop(crop))
        }

        // 3. Resize
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

        // 4. Flip & Flop
        if self.flipHorizontal || self.flipVertical {
            ops.append(.flipFlop(FlipFlopOperation(
                horizontal: self.flipHorizontal,
                vertical: self.flipVertical
            )))
        }

        // 5. Rotate
        if self.rotationDegrees != 0.0 {
            ops.append(.rotate(RotateOperation(degrees: self.rotationDegrees)))
        }

        // 6. Film Simulation Profile
        if self.filmProfile != .none {
            ops.append(.colorGrade(ColorGradeOperation(profile: self.filmProfile)))
        }

        // 7. Color & Tone Adjustments
        if self.brightness != 0.0 || self.contrast != 0.0 || self.saturation != 0.0 {
            ops.append(.colorAdjust(ColorAdjustOperation(
                brightness: self.brightness,
                contrast: self.contrast,
                saturation: self.saturation
            )))
        }

        // 8. Auto Level
        if self.autoLevel {
            ops.append(.autoLevel(AutoLevelOperation(enabled: true)))
        }

        // 9. Input Levels & Gamma
        if self.blackPoint > 0.0 || abs(self.gammaPoint - 1.0) > 0.01 || self.whitePoint < 255.0 {
            ops.append(.levels(LevelsOperation(
                blackPoint: self.blackPoint,
                gamma: self.gammaPoint,
                whitePoint: self.whitePoint
            )))
        }

        // 10. Artistic Tone & Special Effects
        if self.sepia > 0.0 || self.negate || self.denoise > 0.0 {
            ops.append(.artisticTone(ArtisticToneOperation(
                sepia: self.sepia,
                negate: self.negate,
                denoise: self.denoise
            )))
        }

        // 11. Sharpen & Blur
        if self.sharpen > 0.0 || self.blur > 0.0 {
            ops.append(.sharpenBlur(SharpenBlurOperation(
                sharpen: self.sharpen,
                blur: self.blur
            )))
        }

        // 12. Watermark
        if !self.watermarkText.isEmpty {
            ops.append(.watermark(WatermarkOperation(
                text: self.watermarkText,
                fontSize: self.watermarkFontSize,
                opacity: self.watermarkOpacity,
                position: self.watermarkPosition,
                color: self.watermarkColor
            )))
        }

        // 13. Border
        if self.borderWidth > 0 || self.borderHeight > 0 {
            ops.append(.border(BorderOperation(
                width: self.borderWidth,
                height: self.borderHeight,
                color: self.borderColor
            )))
        }

        // 14. 3D Frame
        if self.isFrameEnabled && (self.frameWidth > 0 || self.frameHeight > 0) {
            ops.append(.frame(FrameOperation(
                width: self.frameWidth,
                height: self.frameHeight,
                color: self.frameColor
            )))
        }

        // 15. Artistic & Stylize Filters (Paket C)
        if self.oilPaintRadius > 0.0 {
            ops.append(.oilPaint(OilPaintOperation(radius: self.oilPaintRadius)))
        }
        if self.charcoalRadius > 0.0 {
            ops.append(.charcoal(CharcoalOperation(radius: self.charcoalRadius)))
        }
        if self.sketchRadius > 0.0 {
            ops.append(.sketch(SketchOperation(radius: self.sketchRadius)))
        }
        if self.embossRadius > 0.0 {
            ops.append(.emboss(EmbossOperation(radius: self.embossRadius)))
        }
        if self.edgeRadius > 0.0 {
            ops.append(.edge(EdgeDetectOperation(radius: self.edgeRadius)))
        }
        if self.noiseAmount > 0.0 {
            ops.append(.addNoise(AddNoiseOperation(noiseType: self.noiseType, attenuate: self.noiseAmount)))
        }

        // 16. Colorspace Conversion
        if self.targetColorspace.uppercased() != "SRGB" {
            ops.append(.colorspace(ColorspaceOperation(colorspace: self.targetColorspace)))
        }

        // 17. Bit Depth
        if self.bitDepth != 8 {
            ops.append(.bitDepth(BitDepthOperation(depth: self.bitDepth)))
        }

        // 18. Palette Quantization
        if self.quantizeColors > 0 {
            ops.append(.quantize(QuantizeOperation(numberColors: self.quantizeColors)))
        }

        // 19. Strip Metadata
        if self.stripMetadata {
            ops.append(.stripMetadata(StripMetadataOperation(enabled: true)))
        }

        // 20. Format & Quality
        ops.append(.formatConvert(FormatConvertOperation(format: self.targetFormat, quality: self.quality)))

        return ops
    }
}
