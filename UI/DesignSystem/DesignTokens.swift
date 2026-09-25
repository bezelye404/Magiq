//
//  DesignTokens.swift
//  Magiq
//

import SwiftUI

// MARK: - DesignTokens

public enum DesignTokens {
    public static let spacingSmall: CGFloat = 8
    public static let spacingMedium: CGFloat = 16
    public static let spacingLarge: CGFloat = 24
    public static let cornerRadiusSmall: CGFloat = 6
    public static let cornerRadiusMedium: CGFloat = 10
    public static let cornerRadiusLarge: CGFloat = 16

    public struct AdaptiveMaterialModifier: ViewModifier {
        public func body(content: Content) -> some View {
            if #available(macOS 26.0, *) {
                content.background(.ultraThinMaterial)
            } else {
                content.background(.regularMaterial)
            }
        }
    }
}

// MARK: - View Extension

public extension View {
    func adaptiveMaterial() -> some View {
        self.modifier(DesignTokens.AdaptiveMaterialModifier())
    }
}
