//
//  CheckerboardView.swift
//  Magiq
//

import SwiftUI

// MARK: - CheckerboardView

/// High-performance GPU-rendered checkerboard pattern for transparent canvases.
public struct CheckerboardView: View {
    public let squareSize: CGFloat
    public let color1: Color
    public let color2: Color

    public init(
        squareSize: CGFloat = 12,
        color1: Color = Color.primary.opacity(0.03),
        color2: Color = Color.primary.opacity(0.09)
    ) {
        self.squareSize = squareSize
        self.color1 = color1
        self.color2 = color2
    }

    public var body: some View {
        Canvas { context, size in
            let cols = Int(ceil(size.width / self.squareSize))
            let rows = Int(ceil(size.height / self.squareSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let rect = CGRect(
                        x: CGFloat(col) * self.squareSize,
                        y: CGFloat(row) * self.squareSize,
                        width: self.squareSize,
                        height: self.squareSize
                    )
                    let color = (row + col).isMultiple(of: 2) ? self.color1 : self.color2
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
