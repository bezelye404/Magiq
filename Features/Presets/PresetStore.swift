//
//  PresetStore.swift
//  Magiq
//

import Combine
import Foundation

// MARK: - PresetStore

/// Manages built-in and user-created presets with local JSON persistence.
@MainActor
public final class PresetStore: ObservableObject {
    public static let shared = PresetStore()

    @Published public private(set) var presets: [Preset] = []

    private let fileManager = FileManager.default
    private let storageURL: URL

    public static let builtInPresets: [Preset] = [
        Preset(
            name: "Web-Optimized WebP",
            description: "Scales to max 1920px width, strips EXIF metadata, and converts to 82% WebP for fast web delivery.",
            iconName: "globe",
            isBuiltIn: true,
            operations: [
                .resize(ResizeOperation(width: 1920, height: 1080, maintainAspectRatio: true))
            ],
            outputFormat: "WEBP",
            quality: 82,
            stripMetadata: true
        ),
        Preset(
            name: "Archive Lossless PNG",
            description: "Preserves natural resolution, alpha channels, and color profiles in a lossless PNG container.",
            iconName: "archivebox",
            isBuiltIn: true,
            operations: [],
            outputFormat: "PNG",
            quality: 100,
            stripMetadata: false
        ),
        Preset(
            name: "Social Media Square",
            description: "Prepares images at 1080×1080 resolution with metadata stripped for social posting.",
            iconName: "square",
            isBuiltIn: true,
            operations: [
                .resize(ResizeOperation(width: 1080, height: 1080, maintainAspectRatio: true))
            ],
            outputFormat: "JPEG",
            quality: 90,
            stripMetadata: true
        ),
        Preset(
            name: "Photo Auto-Enhance",
            description: "Applies auto-level histogram correction and subtle sharpening to revitalize captures.",
            iconName: "wand.and.stars",
            isBuiltIn: true,
            operations: [
                .autoLevel(AutoLevelOperation(enabled: true)),
                .sharpenBlur(SharpenBlurOperation(sharpen: 0.8, blur: 0.0))
            ],
            outputFormat: "JPEG",
            quality: 92,
            stripMetadata: false
        ),
        Preset(
            name: "HEIC / RAW to JPEG",
            description: "Converts Apple HEIC or Camera RAW captures into universal high-quality 92% JPEG.",
            iconName: "camera",
            isBuiltIn: true,
            operations: [],
            outputFormat: "JPEG",
            quality: 92,
            stripMetadata: false
        )
    ]

    public init() {
        let appSupport = self.fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let magiqDir = appSupport.appendingPathComponent("Magiq", isDirectory: true)

        try? self.fileManager.createDirectory(at: magiqDir, withIntermediateDirectories: true)
        self.storageURL = magiqDir.appendingPathComponent("presets.json")

        self.loadPresets()
    }

    // MARK: - CRUD Operations

    public func save(preset: Preset) {
        if let index = self.presets.firstIndex(where: { $0.id == preset.id }) {
            self.presets[index] = preset
        } else {
            self.presets.append(preset)
        }
        self.persist()
    }

    public func delete(presetId: UUID) {
        // Built-ins cannot be deleted
        guard let index = self.presets.firstIndex(where: { $0.id == presetId && !$0.isBuiltIn }) else { return }
        self.presets.remove(at: index)
        self.persist()
    }

    public func duplicate(preset: Preset) -> Preset {
        var copy = preset
        copy = Preset(
            id: UUID(),
            name: "\(preset.name) (Copy)",
            description: preset.description,
            iconName: preset.iconName,
            isBuiltIn: false,
            operations: preset.operations,
            outputFormat: preset.outputFormat,
            quality: preset.quality,
            stripMetadata: preset.stripMetadata
        )
        self.save(preset: copy)
        return copy
    }

    public func resetToDefaults() {
        self.presets = Self.builtInPresets
        self.persist()
    }

    // MARK: - Persistence

    private func loadPresets() {
        guard self.fileManager.fileExists(atPath: self.storageURL.path),
              let data = try? Data(contentsOf: self.storageURL),
              let loaded = try? JSONDecoder().decode([Preset].self, from: data),
              !loaded.isEmpty else {
            self.presets = Self.builtInPresets
            self.persist()
            return
        }

        // Ensure built-in presets are always present
        var merged = loaded
        for builtIn in Self.builtInPresets {
            if !merged.contains(where: { $0.name == builtIn.name }) {
                merged.append(builtIn)
            }
        }
        self.presets = merged
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self.presets) {
            try? data.write(to: self.storageURL, options: .atomic)
        }
    }
}
