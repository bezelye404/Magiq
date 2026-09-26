//
//  InspectorView.swift
//  Magiq
//

import SwiftUI

// MARK: - InspectorView

public struct InspectorView: View {
    @Binding var resizeWidth: Int
    @Binding var resizeHeight: Int
    @Binding var maintainAspectRatio: Bool
    @Binding var rotationDegrees: Double
    @Binding var flipHorizontal: Bool
    @Binding var flipVertical: Bool
    @Binding var brightness: Double
    @Binding var contrast: Double
    @Binding var saturation: Double
    @Binding var autoLevel: Bool
    @Binding var filmProfile: FilmProfile
    @Binding var blackPoint: Double
    @Binding var gammaPoint: Double
    @Binding var whitePoint: Double
    @Binding var sepia: Double
    @Binding var negate: Bool
    @Binding var denoise: Double
    @Binding var isAutoTrimmed: Bool
    @Binding var trimFuzz: Double
    @Binding var sharpen: Double
    @Binding var blur: Double
    @Binding var watermarkText: String
    @Binding var watermarkFontSize: Int
    @Binding var watermarkOpacity: Double
    @Binding var watermarkPosition: WatermarkPosition
    @Binding var stripMetadata: Bool
    @Binding var targetFormat: String
    @Binding var quality: Int
    @Binding var targetColorspace: String
    @Binding var bitDepth: Int
    @Binding var quantizeColors: Int
    @Binding var borderWidth: Int
    @Binding var borderHeight: Int
    @Binding var borderColor: String
    @Binding var isFrameEnabled: Bool
    @Binding var frameWidth: Int
    @Binding var frameHeight: Int
    @Binding var frameColor: String
    @Binding var oilPaintRadius: Double
    @Binding var charcoalRadius: Double
    @Binding var sketchRadius: Double
    @Binding var embossRadius: Double
    @Binding var edgeRadius: Double
    @Binding var noiseAmount: Double
    @Binding var noiseType: MagiqNoiseType
    @Binding var isCropping: Bool

    let histogramData: HistogramData?
    let metadata: ImageMetadata?
    let originalWidth: Int?
    let originalHeight: Int?
    let isProcessing: Bool
    let onOptimizeTargetSize: (Int) -> Void
    let onReset: () -> Void
    let onExport: () -> Void

    @State private var targetSizeKB: Int = 500
    @State private var isOptimizingSize: Bool = false

    private let supportedFormats = ["WEBP", "JPEG", "PNG", "TIFF", "AVIF", "HEIC"]

    public init(
        resizeWidth: Binding<Int>,
        resizeHeight: Binding<Int>,
        maintainAspectRatio: Binding<Bool>,
        rotationDegrees: Binding<Double>,
        flipHorizontal: Binding<Bool>,
        flipVertical: Binding<Bool>,
        brightness: Binding<Double>,
        contrast: Binding<Double>,
        saturation: Binding<Double>,
        autoLevel: Binding<Bool>,
        filmProfile: Binding<FilmProfile>,
        blackPoint: Binding<Double> = .constant(0.0),
        gammaPoint: Binding<Double> = .constant(1.0),
        whitePoint: Binding<Double> = .constant(255.0),
        sepia: Binding<Double> = .constant(0.0),
        negate: Binding<Bool> = .constant(false),
        denoise: Binding<Double> = .constant(0.0),
        isAutoTrimmed: Binding<Bool> = .constant(false),
        trimFuzz: Binding<Double> = .constant(5.0),
        sharpen: Binding<Double>,
        blur: Binding<Double>,
        watermarkText: Binding<String>,
        watermarkFontSize: Binding<Int>,
        watermarkOpacity: Binding<Double>,
        watermarkPosition: Binding<WatermarkPosition>,
        stripMetadata: Binding<Bool>,
        targetFormat: Binding<String>,
        quality: Binding<Int>,
        targetColorspace: Binding<String> = .constant("sRGB"),
        bitDepth: Binding<Int> = .constant(8),
        quantizeColors: Binding<Int> = .constant(0),
        borderWidth: Binding<Int> = .constant(0),
        borderHeight: Binding<Int> = .constant(0),
        borderColor: Binding<String> = .constant("black"),
        isFrameEnabled: Binding<Bool> = .constant(false),
        frameWidth: Binding<Int> = .constant(15),
        frameHeight: Binding<Int> = .constant(15),
        frameColor: Binding<String> = .constant("#808080"),
        oilPaintRadius: Binding<Double> = .constant(0.0),
        charcoalRadius: Binding<Double> = .constant(0.0),
        sketchRadius: Binding<Double> = .constant(0.0),
        embossRadius: Binding<Double> = .constant(0.0),
        edgeRadius: Binding<Double> = .constant(0.0),
        noiseAmount: Binding<Double> = .constant(0.0),
        noiseType: Binding<MagiqNoiseType> = .constant(.gaussian),
        isCropping: Binding<Bool>,
        histogramData: HistogramData? = nil,
        metadata: ImageMetadata? = nil,
        originalWidth: Int? = nil,
        originalHeight: Int? = nil,
        isProcessing: Bool,
        onOptimizeTargetSize: @escaping (Int) -> Void = { _ in },
        onReset: @escaping () -> Void,
        onExport: @escaping () -> Void
    ) {
        self._resizeWidth = resizeWidth
        self._resizeHeight = resizeHeight
        self._maintainAspectRatio = maintainAspectRatio
        self._rotationDegrees = rotationDegrees
        self._flipHorizontal = flipHorizontal
        self._flipVertical = flipVertical
        self._brightness = brightness
        self._contrast = contrast
        self._saturation = saturation
        self._autoLevel = autoLevel
        self._filmProfile = filmProfile
        self._blackPoint = blackPoint
        self._gammaPoint = gammaPoint
        self._whitePoint = whitePoint
        self._sepia = sepia
        self._negate = negate
        self._denoise = denoise
        self._isAutoTrimmed = isAutoTrimmed
        self._trimFuzz = trimFuzz
        self._sharpen = sharpen
        self._blur = blur
        self._watermarkText = watermarkText
        self._watermarkFontSize = watermarkFontSize
        self._watermarkOpacity = watermarkOpacity
        self._watermarkPosition = watermarkPosition
        self._stripMetadata = stripMetadata
        self._targetFormat = targetFormat
        self._quality = quality
        self._targetColorspace = targetColorspace
        self._bitDepth = bitDepth
        self._quantizeColors = quantizeColors
        self._borderWidth = borderWidth
        self._borderHeight = borderHeight
        self._borderColor = borderColor
        self._isFrameEnabled = isFrameEnabled
        self._frameWidth = frameWidth
        self._frameHeight = frameHeight
        self._frameColor = frameColor
        self._oilPaintRadius = oilPaintRadius
        self._charcoalRadius = charcoalRadius
        self._sketchRadius = sketchRadius
        self._embossRadius = embossRadius
        self._edgeRadius = edgeRadius
        self._noiseAmount = noiseAmount
        self._noiseType = noiseType
        self._isCropping = isCropping
        self.histogramData = histogramData
        self.metadata = metadata
        self.originalWidth = originalWidth
        self.originalHeight = originalHeight
        self.isProcessing = isProcessing
        self.onOptimizeTargetSize = onOptimizeTargetSize
        self.onReset = onReset
        self.onExport = onExport
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // MARK: - Feature 1: Live Histogram & Zero-Jitter Status
                HistogramView(data: self.histogramData, isProcessing: self.isProcessing)
                    .padding(.bottom, 2)

                // MARK: - Dimensions & Crop (Feature 2)
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                            GridRow {
                                Text("Width")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                TextField("Width", value: self.$resizeWidth, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                                    .onSubmit { self.onWidthChanged() }

                                Text("px")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            GridRow {
                                Text("Height")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                TextField("Height", value: self.$resizeHeight, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                                    .onSubmit { self.onHeightChanged() }

                                Text("px")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Toggle("Maintain Aspect Ratio", isOn: self.$maintainAspectRatio)
                            .font(.subheadline)

                        // Interactive Crop Button
                        Button(action: { self.isCropping.toggle() }) {
                            HStack {
                                Image(systemName: self.isCropping ? "xmark.circle" : "crop")
                                Text(self.isCropping ? "Exit Crop Mode" : "Interactive Crop Tool...")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(self.isCropping ? .orange : .accentColor)
                        .controlSize(.small)

                        // Quick Scale Presets
                        if let origW = self.originalWidth, let origH = self.originalHeight, origW > 0, origH > 0 {
                            HStack(spacing: 4) {
                                ForEach([("100%", 1.0), ("75%", 0.75), ("50%", 0.5), ("25%", 0.25)], id: \.0) { item in
                                    Button(item.0) {
                                        self.resizeWidth = max(1, Int(Double(origW) * item.1))
                                        self.resizeHeight = max(1, Int(Double(origH) * item.1))
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.top, 2)
                        }

                        Divider()

                        // Auto-Trim Borders
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Toggle("Auto-Trim Borders", isOn: self.$isAutoTrimmed)
                                    .font(.subheadline)
                                Spacer()
                                if self.isAutoTrimmed {
                                    Button(action: {
                                        self.isAutoTrimmed = false
                                        self.trimFuzz = 5.0
                                    }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset auto-trim")
                                }
                            }

                            if self.isAutoTrimmed {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("Trim Tolerance (Fuzz)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(Int(self.trimFuzz))%")
                                            .font(.caption.monospacedDigit())
                                    }
                                    Slider(value: self.$trimFuzz, in: 0...30, step: 1)
                                }
                                .padding(.leading, 4)
                            }
                        }
                    }
                    .padding(8)
                } label: {
                    HStack {
                        Label("Dimensions & Crop", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.headline)
                        Spacer()
                        if let origW = self.originalWidth, let origH = self.originalHeight,
                           (self.resizeWidth != origW || self.resizeHeight != origH) {
                            Button(action: {
                                self.resizeWidth = origW
                                self.resizeHeight = origH
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Reset to original image dimensions")
                        }
                    }
                }

                // MARK: - Geometry & Orientation
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Angle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if self.rotationDegrees != 0.0 {
                                Button(action: { self.rotationDegrees = 0.0 }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Reset rotation angle to 0°")
                            }

                            Spacer()

                            Text("\(Int(self.rotationDegrees))°")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: self.$rotationDegrees, in: -180...180, step: 1)

                        HStack(spacing: 6) {
                            Button(action: { self.rotateBy(-90) }) {
                                Label("90° Left", systemImage: "rotate.left")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)

                            Button(action: { self.rotateBy(90) }) {
                                Label("90° Right", systemImage: "rotate.right")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                        }

                        HStack(spacing: 6) {
                            Toggle(isOn: self.$flipHorizontal) {
                                Label("Flip H", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                                    .font(.caption)
                            }
                            .toggleStyle(.button)
                            .frame(maxWidth: .infinity)

                            Toggle(isOn: self.$flipVertical) {
                                Label("Flip V", systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                                    .font(.caption)
                            }
                            .toggleStyle(.button)
                            .frame(maxWidth: .infinity)

                            if self.flipHorizontal || self.flipVertical {
                                Button(action: {
                                    self.flipHorizontal = false
                                    self.flipVertical = false
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Reset flips")
                            }
                        }
                    }
                    .padding(8)
                } label: {
                    Label("Orientation", systemImage: "rotate.3d")
                        .font(.headline)
                }

                // MARK: - Feature 4: Color, Tone & Film Simulation
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        // Film Simulation Profile Picker
                        HStack {
                            Text("Film Look")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if self.filmProfile != .none {
                                Button(action: { self.filmProfile = .none }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Reset film look to none")
                            }

                            Spacer()

                            Picker("Film Look", selection: self.$filmProfile) {
                                ForEach(FilmProfile.allCases) { profile in
                                    Label(profile.rawValue, systemImage: profile.iconName)
                                        .tag(profile)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 120)
                        }

                        Divider()

                        // Brightness
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Brightness")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if self.brightness != 0.0 {
                                    Button(action: { self.brightness = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset brightness to 0")
                                }

                                Spacer()
                                Text("\(Int(self.brightness))")
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$brightness, in: -100...100, step: 1)
                        }

                        // Contrast
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Contrast")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if self.contrast != 0.0 {
                                    Button(action: { self.contrast = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset contrast to 0")
                                }

                                Spacer()
                                Text("\(Int(self.contrast))")
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$contrast, in: -100...100, step: 1)
                        }

                        // Saturation
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Saturation")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if self.saturation != 0.0 {
                                    Button(action: { self.saturation = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset saturation to 0")
                                }

                                Spacer()
                                Text("\(Int(self.saturation))")
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$saturation, in: -100...100, step: 1)
                        }

                        HStack {
                            Toggle("Auto Level (Histogram Balance)", isOn: self.$autoLevel)
                                .font(.caption)
                            Spacer()
                            if self.autoLevel {
                                Button(action: { self.autoLevel = false }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Disable auto level")
                            }
                        }

                        Divider()

                        // Input Levels & Gamma
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Levels & Input Range")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)

                                if self.blackPoint != 0.0 || abs(self.gammaPoint - 1.0) > 0.01 || self.whitePoint != 255.0 {
                                    Button(action: {
                                        self.blackPoint = 0.0
                                        self.gammaPoint = 1.0
                                        self.whitePoint = 255.0
                                    }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset levels to default")
                                }

                                Spacer()
                            }

                            // Black Point
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Black Point")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(Int(self.blackPoint))")
                                        .font(.caption2.monospacedDigit())
                                }
                                Slider(value: self.$blackPoint, in: 0...100, step: 1)
                            }

                            // Gamma
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Gamma")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.2f", self.gammaPoint))
                                        .font(.caption2.monospacedDigit())
                                }
                                Slider(value: self.$gammaPoint, in: 0.2...3.0, step: 0.05)
                            }

                            // White Point
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("White Point")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(Int(self.whitePoint))")
                                        .font(.caption2.monospacedDigit())
                                }
                                Slider(value: self.$whitePoint, in: 155...255, step: 1)
                            }
                        }

                        Divider()

                        // Special Tone & Effects (Invert, Sepia, Denoise)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("Invert Colors (Negate)", isOn: self.$negate)
                                    .font(.caption)
                                Spacer()
                                if self.negate {
                                    Button(action: { self.negate = false }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Disable invert")
                                }
                            }

                            // Sepia Tone
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Sepia Tone")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if self.sepia != 0.0 {
                                        Button(action: { self.sepia = 0.0 }) {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Reset sepia")
                                    }

                                    Spacer()
                                    Text("\(Int(self.sepia))%")
                                        .font(.caption.monospacedDigit())
                                }
                                Slider(value: self.$sepia, in: 0...100, step: 2)
                            }

                            // Denoise
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Noise Reduction")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if self.denoise != 0.0 {
                                        Button(action: { self.denoise = 0.0 }) {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Reset noise reduction")
                                    }

                                    Spacer()
                                    Text(String(format: "%.1f", self.denoise))
                                        .font(.caption.monospacedDigit())
                                }
                                Slider(value: self.$denoise, in: 0...5, step: 0.2)
                            }
                        }
                    }
                    .padding(8)
                } label: {
                    Label("Color & Film Grade", systemImage: "slider.horizontal.2.square")
                        .font(.headline)
                }

                // MARK: - Focal & Clarity
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        // Sharpen
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Sharpen")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if self.sharpen != 0.0 {
                                    Button(action: { self.sharpen = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset sharpen to 0")
                                }

                                Spacer()
                                Text(String(format: "%.1f", self.sharpen))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$sharpen, in: 0...5, step: 0.1)
                        }

                        // Blur
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Blur")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if self.blur != 0.0 {
                                    Button(action: { self.blur = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset blur to 0")
                                }

                                Spacer()
                                Text(String(format: "%.1f", self.blur))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$blur, in: 0...10, step: 0.2)
                        }
                    }
                    .padding(8)
                } label: {
                    Label("Focal & Clarity", systemImage: "camera.filters")
                        .font(.headline)
                }

                // MARK: - Border & Frame (Paket B)
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        // Border Controls
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Border Width")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if self.borderWidth > 0 || self.borderHeight > 0 {
                                    Button(action: {
                                        self.borderWidth = 0
                                        self.borderHeight = 0
                                    }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset border to 0")
                                }

                                Spacer()
                                Text("\(self.borderWidth) px")
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(self.borderWidth) },
                                    set: {
                                        self.borderWidth = Int($0)
                                        self.borderHeight = Int($0)
                                    }
                                ),
                                in: 0...100,
                                step: 1
                            )

                            HStack {
                                Text("Border Color")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("Border Color", selection: self.$borderColor) {
                                    Text("Black").tag("black")
                                    Text("White").tag("white")
                                    Text("Gray").tag("#808080")
                                    Text("Silver").tag("#c0c0c0")
                                    Text("Gold").tag("#d4af37")
                                    Text("Charcoal").tag("#222222")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: 110)
                            }
                        }

                        Divider()

                        // 3D Frame Controls
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("3D Beveled Frame", isOn: self.$isFrameEnabled)
                                .font(.subheadline)

                            if self.isFrameEnabled {
                                HStack {
                                    Text("Frame Size")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if self.frameWidth != 15 || self.frameHeight != 15 {
                                        Button(action: {
                                            self.frameWidth = 15
                                            self.frameHeight = 15
                                        }) {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Reset frame size to 15px")
                                    }

                                    Spacer()
                                    Text("\(self.frameWidth) px")
                                        .font(.caption.monospacedDigit())
                                }
                                Slider(
                                    value: Binding(
                                        get: { Double(self.frameWidth) },
                                        set: {
                                            self.frameWidth = Int($0)
                                            self.frameHeight = Int($0)
                                        }
                                    ),
                                    in: 2...60,
                                    step: 1
                                )

                                HStack {
                                    Text("Mat Color")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Picker("Frame Color", selection: self.$frameColor) {
                                        Text("Classic Gray").tag("#808080")
                                        Text("Matte Black").tag("#222222")
                                        Text("Pure White").tag("white")
                                        Text("Gold Leaf").tag("#d4af37")
                                        Text("Warm Wood").tag("#8b5a2b")
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(width: 110)
                                }
                            }
                        }
                    }
                    .padding(8)
                } label: {
                    Label("Border & Frame", systemImage: "photo.artframe")
                        .font(.headline)
                }

                // MARK: - Artistic & Stylize Filters (Paket C)
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        // Oil Paint
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Oil Paint")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if self.oilPaintRadius > 0.0 {
                                    Button(action: { self.oilPaintRadius = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset oil paint")
                                }
                                Spacer()
                                Text(String(format: "%.1f", self.oilPaintRadius))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$oilPaintRadius, in: 0...10, step: 0.5)
                        }

                        // Charcoal
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Charcoal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if self.charcoalRadius > 0.0 {
                                    Button(action: { self.charcoalRadius = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset charcoal")
                                }
                                Spacer()
                                Text(String(format: "%.1f", self.charcoalRadius))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$charcoalRadius, in: 0...10, step: 0.5)
                        }

                        // Sketch
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Sketch")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if self.sketchRadius > 0.0 {
                                    Button(action: { self.sketchRadius = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset sketch")
                                }
                                Spacer()
                                Text(String(format: "%.1f", self.sketchRadius))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$sketchRadius, in: 0...10, step: 0.5)
                        }

                        // Emboss
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Emboss")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if self.embossRadius > 0.0 {
                                    Button(action: { self.embossRadius = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset emboss")
                                }
                                Spacer()
                                Text(String(format: "%.1f", self.embossRadius))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$embossRadius, in: 0...10, step: 0.5)
                        }

                        // Edge Detect
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Edge Detect")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if self.edgeRadius > 0.0 {
                                    Button(action: { self.edgeRadius = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reset edge detect")
                                }
                                Spacer()
                                Text(String(format: "%.1f", self.edgeRadius))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$edgeRadius, in: 0...10, step: 0.5)
                        }

                        Divider()

                        // Add Synthetic Noise (Grain)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Add Film Noise")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if self.noiseAmount > 0.0 {
                                    Button(action: { self.noiseAmount = 0.0 }) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Remove added noise")
                                }
                                Spacer()
                                Text(String(format: "%.1f", self.noiseAmount))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$noiseAmount, in: 0...5, step: 0.2)

                            if self.noiseAmount > 0.0 {
                                HStack {
                                    Text("Distribution")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Picker("Distribution", selection: self.$noiseType) {
                                        ForEach(MagiqNoiseType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(minWidth: 120)
                                }
                            }
                        }
                    }
                    .padding(8)
                } label: {
                    Label("Stylize & Artistic Filters", systemImage: "paintbrush")
                        .font(.headline)
                }

                // MARK: - Feature 7: Watermark & Text Stamp
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Watermark text (optional)", text: self.$watermarkText)
                            .textFieldStyle(.roundedBorder)

                        if !self.watermarkText.isEmpty {
                            HStack {
                                Text("Size")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Slider(
                                    value: Binding(
                                        get: { Double(self.watermarkFontSize) },
                                        set: { self.watermarkFontSize = Int($0) }
                                    ),
                                    in: 12...80,
                                    step: 2
                                )
                                Text("\(self.watermarkFontSize)pt")
                                    .font(.caption.monospacedDigit())
                            }

                            HStack {
                                Text("Opacity")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Slider(value: self.$watermarkOpacity, in: 0.1...1.0, step: 0.05)
                                Text("\(Int(self.watermarkOpacity * 100))%")
                                    .font(.caption.monospacedDigit())
                            }

                            HStack {
                                Text("Position")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("Position", selection: self.$watermarkPosition) {
                                    ForEach(WatermarkPosition.allCases) { pos in
                                        Text(pos.rawValue).tag(pos)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                        }
                    }
                    .padding(8)
                } label: {
                    HStack {
                        Label("Watermark & Stamp", systemImage: "text.bubble")
                            .font(.headline)
                        Spacer()
                        if !self.watermarkText.isEmpty {
                            Button(action: { self.watermarkText = "" }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Clear watermark text")
                        }
                    }
                }

                // MARK: - EXIF & Photography Metadata (Paket 2)
                MetadataInspectorView(metadata: self.metadata, stripMetadata: self.$stripMetadata)

                // MARK: - Format & Feature 3: Target Size Optimizer
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Format")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("Format", selection: self.$targetFormat) {
                                ForEach(self.supportedFormats, id: \.self) { fmt in
                                    Text(fmt).tag(fmt)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 90)
                        }

                        if self.targetFormat != "PNG" {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Quality")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if self.quality != 85 {
                                        Button(action: { self.quality = 85 }) {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Reset quality to default 85%")
                                    }

                                    Spacer()
                                    Text("\(self.quality)%")
                                        .font(.caption.monospacedDigit())
                                        .bold()
                                }

                                Slider(
                                    value: Binding(
                                        get: { Double(self.quality) },
                                        set: { self.quality = Int($0) }
                                    ),
                                    in: 1...100,
                                    step: 1
                                )

                                // Target Size Optimizer Row
                                HStack(spacing: 6) {
                                    Text("Target:")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    TextField("KB", value: self.$targetSizeKB, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                        .controlSize(.mini)
                                    Text("KB")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)

                                    Spacer()

                                    Button("Optimize Quality") {
                                        self.isOptimizingSize = true
                                        self.onOptimizeTargetSize(self.targetSizeKB * 1024)
                                        self.isOptimizingSize = false
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                    .help("Calculates best compression quality to match target file size budget")
                                }
                                .padding(.top, 4)
                            }
                        }

                        Divider()

                        // Color Space
                        HStack {
                            Text("Color Space")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if self.targetColorspace != "sRGB" {
                                Button(action: { self.targetColorspace = "sRGB" }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Reset color space to sRGB")
                            }

                            Spacer()

                            Picker("Color Space", selection: self.$targetColorspace) {
                                Text("sRGB (Standard)").tag("sRGB")
                                Text("CMYK (Print)").tag("CMYK")
                                Text("Grayscale").tag("Gray")
                                Text("Display P3").tag("Display P3")
                                Text("CIELAB").tag("Lab")
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 110)
                        }

                        // Bit Depth
                        HStack {
                            Text("Bit Depth")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if self.bitDepth != 8 {
                                Button(action: { self.bitDepth = 8 }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Reset bit depth to 8-bit")
                            }

                            Spacer()

                            Picker("Bit Depth", selection: self.$bitDepth) {
                                Text("8-bit (Standard)").tag(8)
                                Text("16-bit (HDR / RAW)").tag(16)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 110)
                        }

                        // Palette Quantization (Quantize)
                        HStack {
                            Text("Quantize (Palette)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if self.quantizeColors > 0 {
                                Button(action: { self.quantizeColors = 0 }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Disable quantization (full colors)")
                            }

                            Spacer()

                            Picker("Quantize", selection: self.$quantizeColors) {
                                Text("Unlimited (Full)").tag(0)
                                Text("256 Colors").tag(256)
                                Text("128 Colors").tag(128)
                                Text("64 Colors").tag(64)
                                Text("32 Colors").tag(32)
                                Text("16 Colors").tag(16)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 110)
                        }

                        Toggle(isOn: self.$stripMetadata) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Strip Metadata (Privacy)")
                                    .font(.subheadline)
                                Text("Removes EXIF, GPS and device identifiers")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(8)
                } label: {
                    Label("Format & Compression", systemImage: "slider.horizontal.3")
                        .font(.headline)
                }

                // MARK: - Action Buttons
                VStack(spacing: 8) {
                    Button(action: self.onExport) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Image...")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Button(action: self.onReset) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Parameters")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
        }
        .safeAreaPadding(.top, 8)
    }

    // MARK: - Actions

    private func rotateBy(_ degrees: Double) {
        let newAngle = (self.rotationDegrees + degrees).truncatingRemainder(dividingBy: 360)
        self.rotationDegrees = newAngle
    }

    private func onWidthChanged() {
        guard self.maintainAspectRatio,
              let origW = self.originalWidth,
              let origH = self.originalHeight,
              origW > 0 else { return }
        let ratio = Double(origH) / Double(origW)
        self.resizeHeight = max(1, Int(Double(self.resizeWidth) * ratio))
    }

    private func onHeightChanged() {
        guard self.maintainAspectRatio,
              let origW = self.originalWidth,
              let origH = self.originalHeight,
              origH > 0 else { return }
        let ratio = Double(origW) / Double(origH)
        self.resizeWidth = max(1, Int(Double(self.resizeHeight) * ratio))
    }
}
