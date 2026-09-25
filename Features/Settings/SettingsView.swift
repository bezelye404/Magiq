//
//  SettingsView.swift
//  Magiq
//

import SwiftUI

// MARK: - SettingsView

public struct SettingsView: View {
    @ObservedObject private var settings = UserSettings.shared
    @ObservedObject private var shortcutManager = KeyboardShortcutManager.shared

    @State private var cachePurgedBanner: Bool = false
    @State private var privacyResetBanner: Bool = false
    @State private var showPrivacyResetConfirmation: Bool = false
    @State private var editingAction: AppAction?

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

            // MARK: - Shortcuts Tab
            VStack(spacing: 0) {
                List {
                    ForEach(ShortcutCategory.allCases, id: \.self) { category in
                        Section(header: Text(category.rawValue).font(.subheadline).bold()) {
                            let actions = AppAction.allCases.filter { $0.category == category }
                            ForEach(actions) { action in
                                let shortcut = self.shortcutManager.shortcut(for: action)
                                HStack {
                                    Text(action.displayName)
                                        .font(.body)

                                    Spacer()

                                    // Key Cap Badge
                                    self.keyCapBadge(shortcut: shortcut)

                                    // Edit Button
                                    Button(action: { self.editingAction = action }) {
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Customize shortcut")

                                    // Reset to default button if customized
                                    if !shortcut.isDefault {
                                        Button(action: { self.shortcutManager.reset(action: action) }) {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.borderless)
                                        .help("Reset to default")
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))

                Divider()

                HStack {
                    Spacer()
                    Button("Reset All Shortcuts to Default") {
                        self.shortcutManager.resetAllToDefaults()
                    }
                    .controlSize(.small)
                }
                .padding(12)
                .background(.ultraThinMaterial)
            }
            .tabItem {
                Label("Shortcuts", systemImage: "command")
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

                Section(header: Text("Data & Metadata Protection")) {
                    Toggle("Strip EXIF / Camera Metadata by Default", isOn: self.$settings.stripMetadataByDefault)
                    Toggle("Clear Document Bookmarks and Recents on Exit", isOn: self.$settings.clearRecentFilesOnExit)
                }

                Section(header: Text("Sandbox & Permission Management")) {
                    Text("Magiq uses App Sandbox security-scoped bookmarks to access only the files and folders you explicitly open.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Button(role: .destructive, action: { self.showPrivacyResetConfirmation = true }) {
                            Label("Reset Privacy Settings to Defaults", systemImage: "arrow.counterclockwise.shield")
                        }
                        .confirmationDialog(
                            "Reset Privacy Settings",
                            isPresented: self.$showPrivacyResetConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Reset & Flush All Permissions", role: .destructive) {
                                self.settings.resetPrivacySettings()
                                self.privacyResetBanner = true
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will purge the thumbnail cache, revoke stored security-scoped folder bookmarks, clear recent document history, and restore default privacy preferences.")
                        }

                        if self.privacyResetBanner {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("All privacy settings, bookmarks, and thumbnail caches have been reset.")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("Privacy", systemImage: "hand.raised.shield")
            }
        }
        .frame(width: 520, height: 420)
        .sheet(item: self.$editingAction) { action in
            ShortcutEditorSheet(action: action)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func keyCapBadge(shortcut: ShortcutItem) -> some View {
        HStack(spacing: 3) {
            if shortcut.control { self.badgeItem("⌃") }
            if shortcut.option { self.badgeItem("⌥") }
            if shortcut.shift { self.badgeItem("⇧") }
            if shortcut.command { self.badgeItem("⌘") }
            self.badgeItem(shortcut.key.uppercased())
        }
    }

    private func badgeItem(_ char: String) -> some View {
        Text(char)
            .font(.caption.monospaced().bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
    }
}

// MARK: - ShortcutEditorSheet

private struct ShortcutEditorSheet: View {
    let action: AppAction
    @Environment(\.dismiss) private var dismiss

    @State private var keyChar: String = ""
    @State private var command: Bool = true
    @State private var shift: Bool = false
    @State private var option: Bool = false
    @State private var control: Bool = false
    @State private var errorMessage: String?

    init(action: AppAction) {
        self.action = action
        let current = KeyboardShortcutManager.shared.shortcut(for: action)
        _keyChar = State(initialValue: current.key)
        _command = State(initialValue: current.command)
        _shift = State(initialValue: current.shift)
        _option = State(initialValue: current.option)
        _control = State(initialValue: current.control)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Shortcut for \(self.action.displayName)")
                .font(.headline)

            Form {
                TextField("Key Character (e.g. o, z, 1)", text: self.$keyChar)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: self.keyChar) { _, newValue in
                        if newValue.count > 1 {
                            self.keyChar = String(newValue.prefix(1))
                        }
                    }

                Section("Modifier Keys") {
                    Toggle("Command (⌘)", isOn: self.$command)
                    Toggle("Shift (⇧)", isOn: self.$shift)
                    Toggle("Option (⌥)", isOn: self.$option)
                    Toggle("Control (⌃)", isOn: self.$control)
                }
            }

            if let err = self.errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel", role: .cancel) {
                    self.dismiss()
                }

                Spacer()

                Button("Save") {
                    guard let first = self.keyChar.trimmingCharacters(in: .whitespaces).first else {
                        self.errorMessage = "Please enter a key character."
                        return
                    }
                    guard self.command || self.shift || self.option || self.control else {
                        self.errorMessage = "Please select at least one modifier key."
                        return
                    }

                    KeyboardShortcutManager.shared.update(
                        action: self.action,
                        key: String(first),
                        command: self.command,
                        shift: self.shift,
                        option: self.option,
                        control: self.control
                    )
                    self.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 320, height: 320)
    }
}
