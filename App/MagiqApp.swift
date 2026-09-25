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

        Settings {
            SettingsView()
        }
    }
}
