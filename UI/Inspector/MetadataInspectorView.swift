//
//  MetadataInspectorView.swift
//  Magiq
//

import AppKit
import SwiftUI

// MARK: - MetadataInspectorView

public struct MetadataInspectorView: View {
    public let metadata: ImageMetadata?
    @Binding public var stripMetadata: Bool

    @State private var isExpanded: Bool = false
    @State private var tagSearchQuery: String = ""
    @State private var copiedNotice: Bool = false

    public init(metadata: ImageMetadata?, stripMetadata: Binding<Bool>) {
        self.metadata = metadata
        self._stripMetadata = stripMetadata
    }

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                if let meta = self.metadata {
                    // MARK: - 1. Photography Camera HUD
                    if meta.hasCameraData {
                        VStack(alignment: .leading, spacing: 6) {
                            if let cam = meta.cameraModel {
                                HStack(spacing: 5) {
                                    Image(systemName: "camera.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                    Text(cam)
                                        .font(.caption.bold())
                                        .lineLimit(1)
                                }
                            }

                            if let lens = meta.lensModel {
                                HStack(spacing: 5) {
                                    Image(systemName: "camera.aperture")
                                        .foregroundStyle(.secondary)
                                    Text(lens)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            // Exposure Settings Badges
                            HStack(spacing: 4) {
                                if let ap = meta.aperture {
                                    self.hudBadge(text: ap, icon: "f.cursive")
                                }
                                if let ss = meta.shutterSpeed {
                                    self.hudBadge(text: ss, icon: "timer")
                                }
                                if let isoVal = meta.iso {
                                    self.hudBadge(text: isoVal, icon: "gauge.with.needle")
                                }
                                if let fl = meta.focalLength {
                                    self.hudBadge(text: fl, icon: "scope")
                                }
                            }
                            .padding(.top, 2)
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    }

                    // MARK: - 2. GPS Location Privacy Alert
                    if meta.hasGPS {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text("GPS Location Data Attached")
                                .font(.caption2.bold())
                                .foregroundStyle(.orange)
                            Spacer()
                            Button("Strip") {
                                self.stripMetadata = true
                            }
                            .controlSize(.mini)
                            .buttonStyle(.bordered)
                        }
                        .padding(6)
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                    }

                    // MARK: - 3. Technical Image Summary
                    Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
                        GridRow {
                            Text("Dimensions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(meta.dimensionsString)
                                .font(.caption.monospacedDigit())
                        }
                        GridRow {
                            Text("Color Space")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(meta.colorspace)
                                .font(.caption)
                        }
                        GridRow {
                            Text("Bit Depth")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(meta.depth)-bit")
                                .font(.caption)
                        }
                        if let size = meta.fileSizeFormatted {
                            GridRow {
                                Text("File Size")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(size)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 2)

                    // MARK: - 4. Searchable EXIF / IPTC Tags
                    if !meta.properties.isEmpty {
                        DisclosureGroup("All Metadata Tags (\(meta.properties.count))", isExpanded: self.$isExpanded) {
                            VStack(spacing: 6) {
                                TextField("Filter tags (e.g. ISO, date, lens)...", text: self.$tagSearchQuery)
                                    .textFieldStyle(.roundedBorder)
                                    .controlSize(.small)

                                ScrollView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(self.filteredProperties(properties: meta.properties), id: \.key) { item in
                                            HStack(alignment: .top) {
                                                Text(item.key)
                                                    .font(.caption2.monospaced())
                                                    .foregroundStyle(.secondary)
                                                    .frame(width: 120, alignment: .leading)
                                                    .lineLimit(1)
                                                Text(item.value)
                                                    .font(.caption2.monospaced())
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .lineLimit(2)
                                            }
                                            .padding(.vertical, 1)
                                            Divider()
                                        }
                                    }
                                }
                                .frame(maxHeight: 160)
                            }
                            .padding(.top, 4)
                        }
                        .font(.caption)
                    }

                    // MARK: - 5. Actions: Copy & Strip
                    HStack(spacing: 6) {
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(meta.formattedSummary, forType: .string)
                            self.copiedNotice = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.copiedNotice = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: self.copiedNotice ? "checkmark" : "doc.on.doc")
                                Text(self.copiedNotice ? "Copied" : "Copy Summary")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Toggle("Strip", isOn: self.$stripMetadata)
                            .toggleStyle(.button)
                            .controlSize(.small)
                            .tint(self.stripMetadata ? .red : .secondary)
                            .help("Strip all EXIF/camera metadata on export")
                    }
                } else {
                    Text("No image loaded")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(8)
        } label: {
            HStack {
                Label("Image Metadata & EXIF", systemImage: "info.circle")
                    .font(.headline)
                Spacer()
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func hudBadge(text: String, icon: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.caption2.monospacedDigit().bold())
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
        .frame(maxWidth: .infinity)
    }

    private func filteredProperties(properties: [String: String]) -> [(key: String, value: String)] {
        let query = self.tagSearchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        let sorted = properties.map { (key: $0.key, value: $0.value) }.sorted { $0.key < $1.key }
        if query.isEmpty {
            return sorted
        }
        return sorted.filter { $0.key.lowercased().contains(query) || $0.value.lowercased().contains(query) }
    }
}
