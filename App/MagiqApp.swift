//
//  MagiqApp.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import SwiftUI

// MARK: - MagiqApp

@main
struct MagiqApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Initialize the global ImageMagick Wand environment
        WandSession.shared.ensureInitialized()
    }

    var body: some Scene {
        // Primary Application Window
        WindowGroup {
            NavigationSplitView {
                SidebarView(selectedMode: self.$appState.navigationMode)
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
            .navigationTitle("Magiq")
            .frame(minWidth: 850, minHeight: 520)
            .adaptiveMaterial()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)

        // Native Settings Window (Command + ,)
        Settings {
            SettingsView()
        }
    }
}
