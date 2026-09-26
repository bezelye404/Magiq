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
    @Binding var sharpen: Double
    @Binding var blur: Double
    @Binding var watermarkText: String
    @Binding var watermarkFontSize: Int
    @Binding var watermarkOpacity: Double
    @Binding var watermarkPosition: WatermarkPosition
    @Binding var stripMetadata: Bool
    @Binding var targetFormat: String
    @Binding var quality: Int
    @Binding var isCropping: Bool

    let histogramData: HistogramData?
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
        sharpen: Binding<Double>,
        blur: Binding<Double>,
        watermarkText: Binding<String>,
        watermarkFontSize: Binding<Int>,
        watermarkOpacity: Binding<Double>,
        watermarkPosition: Binding<WatermarkPosition>,
        stripMetadata: Binding<Bool>,
        targetFormat: Binding<String>,
        quality: Binding<Int>,
        isCropping: Binding<Bool>,
        histogramData: HistogramData? = nil,
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
        self._sharpen = sharpen
        self._blur = blur
        self._watermarkText = watermarkText
        self._watermarkFontSize = watermarkFontSize
        self._watermarkOpacity = watermarkOpacity
        self._watermarkPosition = watermarkPosition
        self._stripMetadata = stripMetadata
        self._targetFormat = targetFormat
        self._quality = quality
        self._isCropping = isCropping
        self.histogramData = histogramData
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
