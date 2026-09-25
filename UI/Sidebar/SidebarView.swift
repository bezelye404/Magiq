//
//  SidebarView.swift
//  Magiq
//

import SwiftUI

// MARK: - NavigationMode

public enum NavigationMode: String, CaseIterable, Identifiable, Hashable {
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

public struct SidebarView: View {
    @Binding var selectedMode: NavigationMode

    public init(selectedMode: Binding<NavigationMode>) {
        self._selectedMode = selectedMode
    }

    public var body: some View {
        List(NavigationMode.allCases, id: \.self, selection: self.$selectedMode) { mode in
            Label(mode.rawValue, systemImage: mode.iconName)
                .tag(mode)
                .padding(.vertical, 3)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
        .safeAreaPadding(.top, 4)
    }
}
