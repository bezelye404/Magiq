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
            .frame(minWidth: 800, minHeight: 500)
            .adaptiveMaterial()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
