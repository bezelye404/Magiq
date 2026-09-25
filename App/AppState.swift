//
//  AppState.swift
//  Magiq
//

import Combine
import SwiftUI

// MARK: - AppState

@MainActor
public final class AppState: ObservableObject {
    @Published public var navigationMode: NavigationMode = .singleImage

    public init() {}
}
