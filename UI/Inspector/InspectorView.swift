//
//  InspectorView.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import SwiftUI

// MARK: - InspectorView

/// Trailing inspector panel for tuning image transform operations.
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
            VStack(alignment: .leading, spacing: DesignTokens.spacingMedium) {
                // Resize Section
                GroupBox(label: Label("Dimensions", systemImage: "arrow.up.left.and.arrow.down.right")) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
                        HStack {
                            Text("Width:")
                                .frame(width: 60, alignment: .leading)
                            TextField("Width", value: self.$resizeWidth, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Text("Height:")
                                .frame(width: 60, alignment: .leading)
                            TextField("Height", value: self.$resizeHeight, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }

                        Toggle("Maintain Aspect Ratio", isOn: self.$maintainAspectRatio)
                            .font(.subheadline)
                    }
                    .padding(.top, 4)
                }

                // Rotation Section
                GroupBox(label: Label("Rotation", systemImage: "rotate.right")) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
                        HStack {
                            Button(action: { self.rotationDegrees = (self.rotationDegrees - 90).truncatingRemainder(dividingBy: 360) }) {
                                Label("Left 90°", systemImage: "rotate.left")
                            }
                            Button(action: { self.rotationDegrees = (self.rotationDegrees + 90).truncatingRemainder(dividingBy: 360) }) {
                                Label("Right 90°", systemImage: "rotate.right")
                            }
                        }

                        HStack {
                            Slider(value: self.$rotationDegrees, in: -180...180, step: 1.0)
                            Text("\(Int(self.rotationDegrees))°")
                                .frame(width: 40)
                                .font(.caption.monospacedDigit())
                        }
                    }
                    .padding(.top, 4)
                }

                // Format & Quality Section
                GroupBox(label: Label("Format & Compression", systemImage: "slider.horizontal.3")) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
                        Picker("Format", selection: self.$targetFormat) {
                            ForEach(self.supportedFormats, id: \.self) { fmt in
                                Text(fmt).tag(fmt)
                            }
                        }
                        .pickerStyle(.menu)

                        if self.targetFormat != "PNG" {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Quality: \(self.quality)%")
                                        .font(.caption)
                                    Spacer()
                                }
                                Slider(value: Binding(
                                    get: { Double(self.quality) },
                                    set: { self.quality = Int($0) }
                                ), in: 1...100, step: 1)
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 20)

                // Actions
                VStack(spacing: DesignTokens.spacingSmall) {
                    Button(action: self.onApply) {
                        HStack {
                            Spacer()
                            Label("Update Preview", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(self.isProcessing)

                    HStack {
                        Button("Reset", action: self.onReset)
                            .buttonStyle(.bordered)
                        Spacer()
                        Button(action: self.onExport) {
                            Label("Export...", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 260, maxWidth: 320)
    }
}
