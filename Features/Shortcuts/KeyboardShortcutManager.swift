//
//  KeyboardShortcutManager.swift
//  Magiq
//

import Combine
import Foundation
import SwiftUI

// MARK: - ModifierKey

public enum ModifierKey: String, CaseIterable, Codable, Sendable, Identifiable {
    case command = "command"
    case shift = "shift"
    case option = "option"
    case control = "control"

    public var id: String { self.rawValue }

    public var symbol: String {
        switch self {
        case .command: return "⌘"
        case .shift: return "⇧"
        case .option: return "⌥"
        case .control: return "⌃"
        }
    }

    public var displayName: String {
        switch self {
        case .command: return "Command"
        case .shift: return "Shift"
        case .option: return "Option"
        case .control: return "Control"
        }
    }
}

// MARK: - ShortcutCategory

public enum ShortcutCategory: String, CaseIterable, Sendable {
    case file = "File & Export"
    case edit = "Edit & Adjustments"
    case view = "Canvas & View"
    case navigation = "Navigation"
}

// MARK: - AppAction

public enum AppAction: String, CaseIterable, Identifiable, Codable, Sendable {
    case openImage = "open_image"
    case exportImage = "export_image"
    case undo = "undo"
    case redo = "redo"
    case resetParameters = "reset_parameters"
    case toggleInspector = "toggle_inspector"
    case toggleCompare = "toggle_compare"
    case zoomIn = "zoom_in"
    case zoomOut = "zoom_out"
    case zoomFit = "zoom_fit"
    case singleDocumentMode = "mode_single"
    case batchQueueMode = "mode_batch"
    case presetsMode = "mode_presets"

    public var id: String { self.rawValue }

    public var displayName: String {
        switch self {
        case .openImage: return "Open Image"
        case .exportImage: return "Export Image"
        case .undo: return "Undo"
        case .redo: return "Redo"
        case .resetParameters: return "Reset Parameters"
        case .toggleInspector: return "Toggle Inspector"
        case .toggleCompare: return "Toggle Compare (Before / After)"
        case .zoomIn: return "Zoom In"
        case .zoomOut: return "Zoom Out"
        case .zoomFit: return "Actual Size / Reset Zoom"
        case .singleDocumentMode: return "Single Document Mode"
        case .batchQueueMode: return "Batch Queue Mode"
        case .presetsMode: return "Presets Mode"
        }
    }

    public var category: ShortcutCategory {
        switch self {
        case .openImage, .exportImage:
            return .file
        case .undo, .redo, .resetParameters:
            return .edit
        case .toggleInspector, .toggleCompare, .zoomIn, .zoomOut, .zoomFit:
            return .view
        case .singleDocumentMode, .batchQueueMode, .presetsMode:
            return .navigation
        }
    }

    public var defaultShortcut: ShortcutItem {
        switch self {
        case .openImage:
            return ShortcutItem(action: self, key: "o", modifiers: [.command])
        case .exportImage:
            return ShortcutItem(action: self, key: "e", modifiers: [.command])
        case .undo:
            return ShortcutItem(action: self, key: "z", modifiers: [.command])
        case .redo:
            return ShortcutItem(action: self, key: "z", modifiers: [.command, .shift])
        case .resetParameters:
            return ShortcutItem(action: self, key: "r", modifiers: [.command])
        case .toggleInspector:
            return ShortcutItem(action: self, key: "i", modifiers: [.command, .option])
        case .toggleCompare:
            return ShortcutItem(action: self, key: "c", modifiers: [.command])
        case .zoomIn:
            return ShortcutItem(action: self, key: "+", modifiers: [.command])
        case .zoomOut:
            return ShortcutItem(action: self, key: "-", modifiers: [.command])
        case .zoomFit:
            return ShortcutItem(action: self, key: "0", modifiers: [.command])
        case .singleDocumentMode:
            return ShortcutItem(action: self, key: "1", modifiers: [.command])
        case .batchQueueMode:
            return ShortcutItem(action: self, key: "2", modifiers: [.command])
        case .presetsMode:
            return ShortcutItem(action: self, key: "3", modifiers: [.command])
        }
    }
}

// MARK: - ShortcutItem

public struct ShortcutItem: Codable, Equatable, Sendable, Identifiable {
    public var id: String { self.action.rawValue }
    public var action: AppAction
    public var key: String
    public var command: Bool
    public var shift: Bool
    public var option: Bool
    public var control: Bool

    public init(action: AppAction, key: String, modifiers: [ModifierKey]) {
        self.action = action
        self.key = key.lowercased()
        self.command = modifiers.contains(.command)
        self.shift = modifiers.contains(.shift)
        self.option = modifiers.contains(.option)
        self.control = modifiers.contains(.control)
    }

    public init(action: AppAction, key: String, command: Bool, shift: Bool, option: Bool, control: Bool) {
        self.action = action
        self.key = key.lowercased()
        self.command = command
        self.shift = shift
        self.option = option
        self.control = control
    }

    public var keyEquivalent: KeyEquivalent {
        let char = self.key.first ?? " "
        return KeyEquivalent(char)
    }

    public var eventModifiers: EventModifiers {
        var mods: EventModifiers = []
        if self.command { mods.insert(.command) }
        if self.shift { mods.insert(.shift) }
        if self.option { mods.insert(.option) }
        if self.control { mods.insert(.control) }
        return mods
    }

    public var displayString: String {
        var result = ""
        if self.control { result += "⌃" }
        if self.option { result += "⌥" }
        if self.shift { result += "⇧" }
        if self.command { result += "⌘" }
        result += self.key.uppercased()
        return result
    }

    public var isDefault: Bool {
        self == self.action.defaultShortcut
    }
}

// MARK: - KeyboardShortcutManager

@MainActor
public final class KeyboardShortcutManager: ObservableObject {
    public static let shared = KeyboardShortcutManager()

    private let userDefaultsKey = "MagiqCustomKeyboardShortcuts_v1"

    @Published public private(set) var shortcuts: [AppAction: ShortcutItem] = [:]

    public init() {
        self.loadShortcuts()
    }

    public func shortcut(for action: AppAction) -> ShortcutItem {
        self.shortcuts[action] ?? action.defaultShortcut
    }

    public func update(action: AppAction, key: String, command: Bool, shift: Bool, option: Bool, control: Bool) {
        guard let validKey = key.first else { return }
        let cleanKey = String(validKey).lowercased()
        let item = ShortcutItem(
            action: action,
            key: cleanKey,
            command: command,
            shift: shift,
            option: option,
            control: control
        )
        self.shortcuts[action] = item
        self.persistShortcuts()
    }

    public func reset(action: AppAction) {
        self.shortcuts[action] = action.defaultShortcut
        self.persistShortcuts()
    }

    public func resetAllToDefaults() {
        var defaults: [AppAction: ShortcutItem] = [:]
        for action in AppAction.allCases {
            defaults[action] = action.defaultShortcut
        }
        self.shortcuts = defaults
        UserDefaults.standard.removeObject(forKey: self.userDefaultsKey)
    }

    // MARK: - Persistence

    private func loadShortcuts() {
        var loaded: [AppAction: ShortcutItem] = [:]
        for action in AppAction.allCases {
            loaded[action] = action.defaultShortcut
        }

        if let data = UserDefaults.standard.data(forKey: self.userDefaultsKey),
           let saved = try? JSONDecoder().decode([String: ShortcutItem].self, from: data) {
            for (rawAction, item) in saved {
                if let action = AppAction(rawValue: rawAction) {
                    loaded[action] = item
                }
            }
        }

        self.shortcuts = loaded
    }

    private func persistShortcuts() {
        var dictionary: [String: ShortcutItem] = [:]
        for (action, item) in self.shortcuts {
            dictionary[action.rawValue] = item
        }

        if let encoded = try? JSONEncoder().encode(dictionary) {
            UserDefaults.standard.set(encoded, forKey: self.userDefaultsKey)
        }
    }
}
