//
//  MagiqApp.swift
//  Magiq
//

import SwiftUI

// MARK: - MagiqApp

@main
struct MagiqApp: App {
    @StateObject private var appState = AppState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    init() {
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
                    SingleDocumentView()
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
                .keyboardShortcut("1", modifiers: .command)

                Button("Batch Queue Mode") {
                    self.appState.navigationMode = .batchQueue
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Presets Mode") {
                    self.appState.navigationMode = .presets
                }
                .keyboardShortcut("3", modifiers: .command)
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
