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
    @Binding var sharpen: Double
    @Binding var blur: Double
    @Binding var stripMetadata: Bool
    @Binding var targetFormat: String
    @Binding var quality: Int

    let originalWidth: Int?
    let originalHeight: Int?
    let isProcessing: Bool
    let onReset: () -> Void
    let onExport: () -> Void

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
        sharpen: Binding<Double>,
        blur: Binding<Double>,
        stripMetadata: Binding<Bool>,
        targetFormat: Binding<String>,
        quality: Binding<Int>,
        originalWidth: Int? = nil,
        originalHeight: Int? = nil,
        isProcessing: Bool,
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
        self._sharpen = sharpen
        self._blur = blur
        self._stripMetadata = stripMetadata
        self._targetFormat = targetFormat
        self._quality = quality
        self.originalWidth = originalWidth
        self.originalHeight = originalHeight
        self.isProcessing = isProcessing
        self.onReset = onReset
        self.onExport = onExport
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Live Status Indicator Banner
                if self.isProcessing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.65)
                            .frame(width: 14, height: 14)
                        Text("Live Rendering...")
                            .font(.caption2.bold())
                            .foregroundStyle(.tint)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }

                // MARK: - Dimensions Group
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
                            .padding(.top, 2)

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
                            .padding(.top, 4)
                        }
                    }
                    .padding(8)
                } label: {
                    Label("Dimensions", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.headline)
                }

                // MARK: - Orientation & Geometry
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Button(action: { self.rotateBy(-90) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "rotate.left")
                                    Text("90° Left")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button(action: { self.rotateBy(90) }) {
                                HStack(spacing: 4) {
                                    Text("90° Right")
                                    Image(systemName: "rotate.right")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        HStack(spacing: 8) {
                            Toggle(isOn: self.$flipHorizontal) {
                                Label("Flip Horizontal", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                                    .font(.caption)
                            }
                            .toggleStyle(.button)
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)

                            Toggle(isOn: self.$flipVertical) {
                                Label("Flip Vertical", systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                                    .font(.caption)
                            }
                            .toggleStyle(.button)
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Angle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(self.rotationDegrees))°")
                                    .font(.caption.monospacedDigit())
                                    .bold()
                            }

                            Slider(value: self.$rotationDegrees, in: -180...180, step: 1.0)
                        }
                    }
                    .padding(8)
                } label: {
                    Label("Orientation", systemImage: "rotate.right")
                        .font(.headline)
                }

                // MARK: - Color & Tone
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Auto Level (Histogram)", isOn: self.$autoLevel)
                            .font(.subheadline)

                        // Brightness
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Brightness")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                                Spacer()
                                Text("\(Int(self.saturation))")
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$saturation, in: -100...100, step: 1)
                        }
                    }
                    .padding(8)
                } label: {
                    Label("Color & Tone", systemImage: "slider.horizontal.2.square")
                        .font(.headline)
                }

                // MARK: - Sharpness & Blur
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Sharpen")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.1f", self.sharpen))
                                    .font(.caption.monospacedDigit())
                            }
                            Slider(value: self.$sharpen, in: 0...5, step: 0.1)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Blur")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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

                // MARK: - Format & Compression
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
