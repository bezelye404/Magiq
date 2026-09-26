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
    @State private var showSandboxResetConfirmation: Bool = false
    @State private var sandboxResetBanner: Bool = false
    @State private var copiedTerminalCommand: Bool = false
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

            // MARK: - Privacy & Security Tab
            ScrollView {
                Form {
                    Section(header: Text("Privacy by Construction")) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Zero Network Access & Zero Telemetry")
                                    .font(.headline)
                                Text("Magiq makes no outbound network connections, includes no third-party tracking SDKs, and processes all files strictly locally on Apple Silicon.")
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

                    Section(header: Text("App Sandbox & Folder Access")) {
                        Text("Magiq operates within the native macOS App Sandbox. Access to folders and files is managed via security-scoped bookmarks granted by you.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Button(role: .destructive, action: { self.showSandboxResetConfirmation = true }) {
                                Label("Revoke Magiq Folder Bookmarks", systemImage: "xmark.bin")
                            }
                            .confirmationDialog(
                                "Revoke Sandbox Bookmarks",
                                isPresented: self.$showSandboxResetConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Revoke All Bookmarks", role: .destructive) {
                                    self.settings.resetSandboxPermissions()
                                    self.sandboxResetBanner = true
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("This revokes all stored security-scoped folder bookmarks. The next time you open folders or batch queues, macOS will ask for authorization again.")
                            }

                            if self.sandboxResetBanner {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Security-scoped bookmarks have been flushed.")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                                .padding(.top, 2)
                            }
                        }
                    }

                    Section(header: Text("Apple System Permissions (TCC)")) {
                        Text("macOS manages system-level Files & Folders access independently in System Settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button(action: {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders"),
                               NSWorkspace.shared.open(url) {
                                // Opened Privacy_FilesAndFolders
                            } else if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
                                NSWorkspace.shared.open(fallback)
                            }
                        }) {
                            Label("Open macOS Privacy & Security Settings…", systemImage: "arrow.up.forward.app")
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reset via Terminal (Power Users):")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("tccutil reset All com.magiq.app")
                                    .font(.caption.monospaced())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))

                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString("tccutil reset All com.magiq.app", forType: .string)
                                    self.copiedTerminalCommand = true
                                }) {
                                    Image(systemName: self.copiedTerminalCommand ? "checkmark" : "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                                .help("Copy command to clipboard")

                                if self.copiedTerminalCommand {
                                    Text("Copied!")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    Section(header: Text("Reset All Privacy Defaults")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(role: .destructive, action: { self.showPrivacyResetConfirmation = true }) {
                                Label("Reset All Privacy Settings & Flush Caches", systemImage: "arrow.counterclockwise.shield")
                            }
                            .confirmationDialog(
                                "Reset Privacy Settings",
                                isPresented: self.$showPrivacyResetConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Reset & Flush Everything", role: .destructive) {
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
            }
            .tabItem {
                Label("Privacy", systemImage: "hand.raised.fill")
            }
        }
        .frame(width: 540, height: 480)
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
