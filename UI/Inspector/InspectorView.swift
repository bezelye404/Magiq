//
//  InspectorView.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import SwiftUI

// MARK: - InspectorView

/// Trailing inspector panel for configuring transform operations and format settings.
///
/// Designed to fit natively inside macOS `.inspector(isPresented:)` container.
public struct InspectorView: View {
    @Binding var resizeWidth: Int
    @Binding var resizeHeight: Int
    @Binding var maintainAspectRatio: Bool
    @Binding var rotationDegrees: Double
    @Binding var targetFormat: String
    @Binding var quality: Int

    let isProcessing: Bool
    let onApply: () -> Void
    let onReset: () -> Void
    let onExport: () -> Void

    private let supportedFormats = ["WEBP", "JPEG", "PNG", "TIFF", "AVIF", "HEIC"]

    public init(
        resizeWidth: Binding<Int>,
        resizeHeight: Binding<Int>,
        maintainAspectRatio: Binding<Bool>,
        rotationDegrees: Binding<Double>,
        targetFormat: Binding<String>,
        quality: Binding<Int>,
        isProcessing: Bool,
        onApply: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onExport: @escaping () -> Void
    ) {
        self._resizeWidth = resizeWidth
        self._resizeHeight = resizeHeight
        self._maintainAspectRatio = maintainAspectRatio
        self._rotationDegrees = rotationDegrees
        self._targetFormat = targetFormat
        self._quality = quality
        self.isProcessing = isProcessing
        self.onApply = onApply
        self.onReset = onReset
        self.onExport = onExport
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Dimensions Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                            GridRow {
                                Text("Width")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .leading)

                                TextField("Width", value: self.$resizeWidth, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)

                                Text("px")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            GridRow {
                                Text("Height")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .leading)

                                TextField("Height", value: self.$resizeHeight, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)

                                Text("px")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Toggle("Maintain Aspect Ratio", isOn: self.$maintainAspectRatio)
                            .font(.subheadline)
                            .padding(.top, 2)
                    }
                    .padding(8)
                } label: {
                    Label("Dimensions", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.headline)
                }

                // Rotation Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Button(action: { self.rotateBy(-90) }) {
                                HStack {
                                    Image(systemName: "rotate.left")
                                    Text("90° Left")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button(action: { self.rotateBy(90) }) {
                                HStack {
                                    Text("90° Right")
                                    Image(systemName: "rotate.right")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
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
                    Label("Rotation", systemImage: "rotate.right")
                        .font(.headline)
                }

                // Format & Compression Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
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
                            .frame(width: 100)
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
                    }
                    .padding(8)
                } label: {
                    Label("Format & Compression", systemImage: "slider.horizontal.3")
                        .font(.headline)
                }

                // Action Buttons Section
                VStack(spacing: 10) {
                    Button(action: self.onApply) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Update Preview")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(self.isProcessing)

                    HStack(spacing: 8) {
                        Button("Reset", action: self.onReset)
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .frame(maxWidth: .infinity)

                        Button(action: self.onExport) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export...")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)
    }

    private func rotateBy(_ degrees: Double) {
        let newAngle = (self.rotationDegrees + degrees).truncatingRemainder(dividingBy: 360)
        self.rotationDegrees = newAngle
    }
}
