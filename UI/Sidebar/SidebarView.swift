//
//  SidebarView.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import SwiftUI

// MARK: - NavigationMode

public enum NavigationMode: String, CaseIterable, Identifiable {
    case singleImage = "Single Image"
    case batchQueue = "Batch Queue"
    case presets = "Presets"

    public var id: String { self.rawValue }

    public var iconName: String {
        switch self {
        case .singleImage: return "photo"
        case .batchQueue: return "square.stack.3d.down.right"
        case .presets: return "slider.horizontal.3"
        }
    }
}

// MARK: - SidebarView

/// Primary sidebar for navigating between Single Image, Batch Queue, and Presets modes.
public struct SidebarView: View {
    @Binding var selectedMode: NavigationMode

    public init(selectedMode: Binding<NavigationMode>) {
        self._selectedMode = selectedMode
    }

    public var body: some View {
        List(NavigationMode.allCases, selection: self.$selectedMode) { mode in
            NavigationLink(value: mode) {
                Label(mode.rawValue, systemImage: mode.iconName)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
    }
}
