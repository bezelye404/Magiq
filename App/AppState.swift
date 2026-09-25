//
//  AppState.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Combine
import SwiftUI

// MARK: - AppState

/// Global state manager for the Magiq application.
@MainActor
public final class AppState: ObservableObject {
    @Published public var navigationMode: NavigationMode = .singleImage

    public init() {}
}
