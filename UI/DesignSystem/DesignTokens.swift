//
//  DesignTokens.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import SwiftUI

// MARK: - DesignTokens

/// Apple HIG-compliant design tokens, typography, and adaptive system materials.
public enum DesignTokens {
    // MARK: - Spacing & Corner Radii

    public static let spacingSmall: CGFloat = 8
    public static let spacingMedium: CGFloat = 16
    public static let spacingLarge: CGFloat = 24
    public static let cornerRadiusSmall: CGFloat = 6
    public static let cornerRadiusMedium: CGFloat = 10
    public static let cornerRadiusLarge: CGFloat = 16

    // MARK: - Glass & Material Backgrounds

    /// Adaptive background modifier applying Liquid Glass on macOS 26+ or thin material on macOS 15.
    public struct AdaptiveMaterialModifier: ViewModifier {
        public func body(content: Content) -> some View {
            if #available(macOS 26.0, *) {
                content
                    .background(.ultraThinMaterial)
            } else {
                content
                    .background(.regularMaterial)
            }
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Applies the adaptive HIG material background to the view.
    func adaptiveMaterial() -> some View {
        self.modifier(DesignTokens.AdaptiveMaterialModifier())
    }
}
