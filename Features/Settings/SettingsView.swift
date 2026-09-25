//
//  SettingsView.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import SwiftUI

// MARK: - SettingsView

/// Dedicated Preferences / Settings window conforming to macOS HIG standards.
public struct SettingsView: View {
    @ObservedObject private var settings = UserSettings.shared
    @State private var cachePurgedBanner: Bool = false

    private let supportedFormats = ["WEBP", "JPEG", "PNG", "TIFF", "AVIF", "HEIC"]
    private let canvasOptions = ["Neutral Dark", "Subtle Checkerboard", "Solid Black", "System"]

    public init() {}

    public var body: some View {
        TabView {
            // MARK: - General Tab
            Form {
                Section(header: Text("Export Defaults")) {
                    Picker("Default Format", selection: self.$settings.defaultFormat) {
                        ForEach(self.supportedFormats, id: \.self) { fmt in
                            Text(fmt).tag(fmt)
                        }
                    }

                    if self.settings.defaultFormat != "PNG" {
                        Slider(
                            value: Binding(
                                get: { Double(self.settings.defaultQuality) },
                                set: { self.settings.defaultQuality = Int($0) }
                            ),
                            in: 1...100,
                            step: 1
                        ) {
                            Text("Default Quality (\(self.settings.defaultQuality)%)")
                        }
                    }

                    Toggle("Preserve EXIF / Color Metadata", isOn: self.$settings.preserveMetadata)
                }

                Section(header: Text("Viewing Behavior")) {
                    Toggle("Auto-fit image to viewport on open", isOn: self.$settings.autoFitOnOpen)
                }
            }
            .padding(20)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            // MARK: - Performance Tab
            Form {
                Section(header: Text("Concurrency & Worker Pool")) {
                    Stepper(
                        "Parallel Batch Workers: \(self.settings.workerCount)",
                        value: self.$settings.workerCount,
                        in: 1...ProcessInfo.processInfo.activeProcessorCount
                    )
                    Text("Optimal default is physical cores minus one to keep UI responsive.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(header: Text("RAM & Cache Budget")) {
                    Slider(
                        value: Binding(
                            get: { Double(self.settings.maxCacheMemoryMB) },
                            set: { self.settings.maxCacheMemoryMB = Int($0) }
                        ),
                        in: 50...1024,
                        step: 50
                    ) {
                        Text("Preview Cache Limit: \(self.settings.maxCacheMemoryMB) MB")
                    }

                    HStack {
                        Button("Purge Thumbnail Cache Now") {
                            self.settings.clearThumbnailCache()
                            self.cachePurgedBanner = true
                        }

                        if self.cachePurgedBanner {
                            Text("Cache cleared")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("Performance", systemImage: "cpu")
            }

            // MARK: - Canvas Tab
            Form {
                Section(header: Text("Canvas Appearance")) {
                    Picker("Canvas Background", selection: self.$settings.canvasBackground) {
                        ForEach(self.canvasOptions, id: \.self) { opt in
                            Text(opt).tag(opt)
                        }
                    }

                    Slider(value: self.$settings.zoomSensitivity, in: 1.1...2.0, step: 0.05) {
                        Text("Zoom Sensitivity (\(String(format: "%.2f", self.settings.zoomSensitivity))x)")
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("Canvas", systemImage: "paintpalette")
            }

            // MARK: - Privacy Tab
            Form {
                Section(header: Text("Privacy by Construction")) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Zero Network Access & Zero Telemetry")
                                .font(.headline)
                            Text("Magiq makes no outbound network connections, includes no third-party tracking SDKs, and processes all files strictly locally.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Sandbox & Access Permissions")) {
                    Text("Folder watch and batch items utilize standard macOS security-scoped bookmarks, revocable at any time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .tabItem {
                Label("Privacy", systemImage: "hand.raised.shield")
            }
        }
        .frame(width: 480, height: 320)
    }
}
