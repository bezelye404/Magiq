//
//  MagiqApp.swift
//  Magiq
//

import SwiftUI

// MARK: - MagiqApp

@main
struct MagiqApp: App {
    @StateObject private var appState = AppState()
    @ObservedObject private var shortcuts = KeyboardShortcutManager.shared
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    init() {
        HeadlessRunner.runIfHeadless()
        WandSession.shared.ensureInitialized()
    }

    var body: some Scene {
        WindowGroup {
            NavigationSplitView(columnVisibility: self.$columnVisibility) {
                SidebarView(selectedMode: self.$appState.navigationMode)
                    .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 260)
            } detail: {
                switch self.appState.navigationMode {
                case .singleImage:
                    SingleDocumentView(viewModel: self.appState.documentViewModel)
                case .batchQueue:
                    BatchQueueView()
                case .presets:
                    PresetsView()
                }
            }
            .navigationSplitViewStyle(.balanced)
            .navigationTitle("Magiq")
            .frame(minWidth: 780, minHeight: 480)
            .adaptiveMaterial()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Single Document Mode") {
                    self.appState.navigationMode = .singleImage
                }
                .keyboardShortcut(
                    self.shortcuts.shortcut(for: .singleDocumentMode).keyEquivalent,
                    modifiers: self.shortcuts.shortcut(for: .singleDocumentMode).eventModifiers
                )

                Button("Batch Queue Mode") {
                    self.appState.navigationMode = .batchQueue
                }
                .keyboardShortcut(
                    self.shortcuts.shortcut(for: .batchQueueMode).keyEquivalent,
                    modifiers: self.shortcuts.shortcut(for: .batchQueueMode).eventModifiers
                )

                Button("Presets Mode") {
                    self.appState.navigationMode = .presets
                }
                .keyboardShortcut(
                    self.shortcuts.shortcut(for: .presetsMode).keyEquivalent,
                    modifiers: self.shortcuts.shortcut(for: .presetsMode).eventModifiers
                )
            }

            CommandMenu("View") {
                Button("Toggle Sidebar") {
                    if self.columnVisibility == .detailOnly {
                        self.columnVisibility = .all
                    } else {
                        self.columnVisibility = .detailOnly
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
        }

        Settings {
            SettingsView()
        }
    }
}
