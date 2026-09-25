//
//  FilmPresets.swift
//  Magiq
//

import Foundation

// MARK: - FilmProfile

public enum FilmProfile: String, CaseIterable, Identifiable, Codable, Sendable {
    case none = "None"
    case portraWarm = "Kodak Portra Warm"
    case velviaVivid = "Fuji Velvia Vivid"
    case triXNoir = "Tri-X 400 Noir"
    case cinematicTealOrange = "Cinematic Teal & Orange"
    case vintage70s = "Vintage Matte 1970s"

    public var id: String { self.rawValue }

    public var iconName: String {
        switch self {
        case .none: return "slash.circle"
        case .portraWarm: return "sun.max"
        case .velviaVivid: return "mountain.2"
        case .triXNoir: return "circle.lefthalf.filled"
        case .cinematicTealOrange: return "film"
        case .vintage70s: return "camera.filters"
        }
    }
}

// MARK: - ColorGradeOperation

public struct ColorGradeOperation: ImageOperation, Equatable {
    public let id: UUID
    public var name: String { "Film Simulation (\(self.profile.rawValue))" }
    public var profile: FilmProfile

    public init(id: UUID = UUID(), profile: FilmProfile = .none) {
        self.id = id
        self.profile = profile
    }

    public func apply(to wand: ImageWand) throws {
        switch self.profile {
        case .none:
            break
        case .portraWarm:
            // Warm tones: slightly higher brightness, rich warm saturation
            try wand.brightnessContrast(brightness: 4.0, contrast: 6.0)
            try wand.modulate(brightness: 102.0, saturation: 110.0, hue: 102.0)
        case .velviaVivid:
            // High saturation, crisp contrast
            try wand.brightnessContrast(brightness: -2.0, contrast: 15.0)
            try wand.modulate(brightness: 100.0, saturation: 135.0, hue: 100.0)
        case .triXNoir:
            // Monochromatic high contrast
            try wand.modulate(brightness: 100.0, saturation: 0.0, hue: 100.0)
            try wand.brightnessContrast(brightness: 5.0, contrast: 25.0)
            try wand.autoLevel()
        case .cinematicTealOrange:
            // Contrast punch + warm highlights
            try wand.brightnessContrast(brightness: 2.0, contrast: 12.0)
            try wand.modulate(brightness: 98.0, saturation: 115.0, hue: 105.0)
        case .vintage70s:
            // Faded blacks, warmer tint
            try wand.brightnessContrast(brightness: 8.0, contrast: -10.0)
            try wand.modulate(brightness: 105.0, saturation: 90.0, hue: 108.0)
        }
    }

    public var cliArguments: [String] {
        switch self.profile {
        case .none:
            return []
        case .portraWarm:
            return ["-brightness-contrast", "4x6", "-modulate", "102,110,102"]
        case .velviaVivid:
            return ["-brightness-contrast", "-2x15", "-modulate", "100,135,100"]
        case .triXNoir:
            return ["-modulate", "100,0,100", "-brightness-contrast", "5x25", "-auto-level"]
        case .cinematicTealOrange:
            return ["-brightness-contrast", "2x12", "-modulate", "98,115,105"]
        case .vintage70s:
            return ["-brightness-contrast", "8x-10", "-modulate", "105,90,108"]
        }
    }
}
