//
//  BatchQueueView.swift
//  Magiq
//

import SwiftUI

public struct BatchQueueView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: DesignTokens.spacingLarge) {
            Image(systemName: "square.stack.3d.down.right")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            Text("Batch Queue")
                .font(.title2)
                .bold()

            Text("Drag folders or image sets here to process with bounded memory workers.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
