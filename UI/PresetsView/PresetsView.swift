//
//  PresetsView.swift
//  Magiq
//

import SwiftUI

// MARK: - PresetsView

public struct PresetsView: View {
    @ObservedObject private var store = PresetStore.shared
    @State private var selectedPresetID: UUID?
    @State private var searchText: String = ""
    @State private var isCreatingNew: Bool = false

    public init() {}

    private var filteredPresets: [Preset] {
        if self.searchText.isEmpty {
            return self.store.presets
        } else {
            return self.store.presets.filter {
                $0.name.localizedCaseInsensitiveContains(self.searchText) ||
                $0.description.localizedCaseInsensitiveContains(self.searchText) ||
                $0.outputFormat.localizedCaseInsensitiveContains(self.searchText)
            }
        }
    }

    private var selectedPresetBinding: Binding<Preset>? {
        guard let id = self.selectedPresetID,
              let index = self.store.presets.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return Binding(
            get: { self.store.presets[index] },
            set: { self.store.save(preset: $0) }
        )
    }

    public var body: some View {
        HSplitView {
            // Left List Column
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search presets...", text: self.$searchText)
                        .textFieldStyle(.plain)
                    if !self.searchText.isEmpty {
                        Button(action: { self.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                List(selection: self.$selectedPresetID) {
                    Section("Built-in Recipes") {
                        ForEach(self.filteredPresets.filter { $0.isBuiltIn }) { preset in
                            self.presetRow(preset)
                                .tag(preset.id)
                        }
                    }

                    let customPresets = self.filteredPresets.filter { !$0.isBuiltIn }
                    if !customPresets.isEmpty {
                        Section("Custom Presets") {
                            ForEach(customPresets) { preset in
                                self.presetRow(preset)
                                    .tag(preset.id)
                                    .contextMenu {
                                        Button("Duplicate") {
                                            let copy = self.store.duplicate(preset: preset)
                                            self.selectedPresetID = copy.id
                                        }
                                        Button("Delete", role: .destructive) {
                                            self.store.delete(presetId: preset.id)
                                            if self.selectedPresetID == preset.id {
                                                self.selectedPresetID = self.store.presets.first?.id
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)

                Divider()

                // Bottom toolbar
                HStack {
                    Button(action: self.createNewPreset) {
                        Label("New Preset", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                    .font(.subheadline)

                    Spacer()

                    Button(action: { self.store.resetToDefaults() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Restore Default Presets")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .frame(minWidth: 260, idealWidth: 300, maxWidth: 360)

            // Right Detail Column
            Group {
                if let binding = self.selectedPresetBinding {
                    PresetDetailView(preset: binding)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.secondary)
                        Text("No Preset Selected")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Select a recipe from the list or create a new one.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if self.selectedPresetID == nil {
                self.selectedPresetID = self.store.presets.first?.id
            }
        }
    }

    private func presetRow(_ preset: Preset) -> some View {
        HStack(spacing: 10) {
            Image(systemName: preset.iconName)
                .font(.system(size: 16))
                .foregroundStyle(.tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(preset.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Text(preset.outputFormat)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }

                Text(preset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func createNewPreset() {
        let newPreset = Preset(
            name: "Untitled Recipe",
            description: "Custom multi-step image transformation recipe.",
            iconName: "sparkles",
            isBuiltIn: false,
            operations: [
                .resize(ResizeOperation(width: 1920, height: 1080, maintainAspectRatio: true))
            ],
            outputFormat: "WEBP",
            quality: 85,
            stripMetadata: true
        )
        self.store.save(preset: newPreset)
        self.selectedPresetID = newPreset.id
    }
}

// MARK: - PresetDetailView

private struct PresetDetailView: View {
    @Binding var preset: Preset
    @ObservedObject private var store = PresetStore.shared

    private let supportedFormats = ["WEBP", "JPEG", "PNG", "TIFF", "AVIF", "HEIC"]
    private let availableIcons = ["globe", "archivebox", "square", "wand.and.stars", "camera", "sparkles", "bolt", "photo.stack", "slider.horizontal.3"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header card
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Menu {
                                ForEach(self.availableIcons, id: \.self) { icon in
                                    Button(action: { if !self.preset.isBuiltIn { self.preset.iconName = icon } }) {
                                        Label(icon, systemImage: icon)
                                    }
                                }
                            } label: {
                                Image(systemName: self.preset.iconName)
                                    .font(.system(size: 24))
                                    .foregroundStyle(.tint)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }
                            .menuStyle(.borderlessButton)
                            .disabled(self.preset.isBuiltIn)

                            VStack(alignment: .leading, spacing: 4) {
                                if self.preset.isBuiltIn {
                                    HStack {
                                        Text(self.preset.name)
                                            .font(.title3.bold())
                                        Spacer()
                                        Text("Built-in")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.secondary.opacity(0.2), in: Capsule())
                                    }
                                } else {
                                    TextField("Preset Name", text: self.$preset.name)
                                        .font(.title3.bold())
                                        .textFieldStyle(.roundedBorder)
                                }

                                if self.preset.isBuiltIn {
                                    Text(self.preset.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    TextField("Description", text: self.$preset.description)
                                        .font(.caption)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    }
                    .padding(10)
                }

                // Output Format & Quality
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Target Format")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("Format", selection: self.$preset.outputFormat) {
                                ForEach(self.supportedFormats, id: \.self) { fmt in
                                    Text(fmt).tag(fmt)
                                }
                            }
                            .disabled(self.preset.isBuiltIn)
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 100)
                        }

                        if self.preset.outputFormat != "PNG" {
                            HStack {
                                Text("Quality (\(self.preset.quality)%)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Slider(
                                    value: Binding(
                                        get: { Double(self.preset.quality) },
                                        set: { self.preset.quality = Int($0) }
                                    ),
                                    in: 1...100,
                                    step: 1
                                )
                                .disabled(self.preset.isBuiltIn)
                                .frame(width: 180)
                            }
                        }

                        Toggle("Strip EXIF & Location Metadata", isOn: self.$preset.stripMetadata)
                            .font(.subheadline)
                            .disabled(self.preset.isBuiltIn)
                    }
                    .padding(8)
                } label: {
                    Label("Export Target", systemImage: "square.and.arrow.up")
                        .font(.headline)
                }

                // Steps / Operations Chain
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        if self.preset.operations.isEmpty {
                            Text("No transformation steps. The image will be exported directly in the target format.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(Array(self.preset.operations.enumerated()), id: \.element.id) { index, op in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(op.name)
                                            .font(.subheadline.bold())
                                        Text(op.cliArguments.joined(separator: " "))
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if !self.preset.isBuiltIn {
                                        Button(action: { self.preset.operations.remove(at: index) }) {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundStyle(.red.opacity(0.8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                            }
                        }

                        if !self.preset.isBuiltIn {
                            Menu {
                                Button("Add Resize") {
                                    self.preset.operations.append(.resize(ResizeOperation(width: 1920, height: 1080)))
                                }
                                Button("Add Auto Level") {
                                    self.preset.operations.append(.autoLevel(AutoLevelOperation(enabled: true)))
                                }
                                Button("Add Color Adjustments") {
                                    self.preset.operations.append(.colorAdjust(ColorAdjustOperation(brightness: 0, contrast: 10, saturation: 10)))
                                }
                                Button("Add Sharpen") {
                                    self.preset.operations.append(.sharpenBlur(SharpenBlurOperation(sharpen: 1.0, blur: 0)))
                                }
                                Button("Add Flip / Flop") {
                                    self.preset.operations.append(.flipFlop(FlipFlopOperation(horizontal: true, vertical: false)))
                                }
                            } label: {
                                Label("Add Operation Step", systemImage: "plus.circle")
                                    .font(.subheadline)
                            }
                            .menuStyle(.borderedButton)
                            .padding(.top, 4)
                        }
                    }
                    .padding(8)
                } label: {
                    Label("Recipe Pipeline (\(self.preset.operations.count) steps)", systemImage: "list.bullet.indent")
                        .font(.headline)
                }

                // Actions bar
                HStack(spacing: 12) {
                    Button(action: {
                        _ = self.store.duplicate(preset: self.preset)
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Duplicate Preset")
                        }
                    }
                    .buttonStyle(.bordered)

                    if !self.preset.isBuiltIn {
                        Button(role: .destructive, action: {
                            self.store.delete(presetId: self.preset.id)
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()
                }
                .padding(.top, 6)
            }
            .padding(20)
        }
    }
}
