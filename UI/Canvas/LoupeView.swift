//
//  LoupeView.swift
//  Magiq
//

import AppKit
import SwiftUI

// MARK: - LoupeView

public struct LoupeView: View {
    public let image: NSImage
    public let targetPoint: CGPoint
    public let viewSize: CGSize
    public let magnification: CGFloat

    public init(
        image: NSImage,
        targetPoint: CGPoint,
        viewSize: CGSize,
        magnification: CGFloat = 3.0
    ) {
        self.image = image
        self.targetPoint = targetPoint
        self.viewSize = viewSize
        self.magnification = magnification
    }

    public var body: some View {
        let loupeSize: CGFloat = 130
        let halfLoupe = loupeSize / 2.0

        // Calculate offset within the image to center targetPoint
        let normX = self.targetPoint.x / max(1.0, self.viewSize.width)
        let normY = self.targetPoint.y / max(1.0, self.viewSize.height)

        let offsetX = (0.5 - normX) * self.viewSize.width * self.magnification
        let offsetY = (0.5 - normY) * self.viewSize.height * self.magnification

        ZStack {
            // Magnified Image Crop
            Image(nsImage: self.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: self.viewSize.width * self.magnification, height: self.viewSize.height * self.magnification)
                .offset(x: offsetX, y: offsetY)
                .frame(width: loupeSize, height: loupeSize)
                .clipShape(Circle())

            // Center Crosshair
            Path { path in
                let center = CGPoint(x: halfLoupe, y: halfLoupe)
                path.move(to: CGPoint(x: center.x - 8, y: center.y))
                path.addLine(to: CGPoint(x: center.x + 8, y: center.y))
                path.move(to: CGPoint(x: center.x, y: center.y - 8))
                path.addLine(to: CGPoint(x: center.x, y: center.y + 8))
            }
            .stroke(Color.white, lineWidth: 1.5)
            .shadow(color: .black.opacity(0.8), radius: 1)

            // Outer HIG Lens Ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.9), Color.white.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: loupeSize, height: loupeSize)
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)

            // Magnification Badge
            VStack {
                Spacer()
                Text("\(Int(self.magnification))x")
                    .font(.caption2.monospaced().bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5))
                    .padding(.bottom, 6)
            }
            .frame(width: loupeSize, height: loupeSize)
        }
        .position(x: self.targetPoint.x, y: max(halfLoupe + 10, self.targetPoint.y - halfLoupe - 20))
    }
}
