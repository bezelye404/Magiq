//
//  PresetsView.swift
//  Magiq
//

import SwiftUI

public struct PresetsView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: DesignTokens.spacingLarge) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            Text("Presets")
                .font(.title2)
                .bold()

            Text("Configure and save reusable multi-step recipes like Web-Optimized WebP.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
