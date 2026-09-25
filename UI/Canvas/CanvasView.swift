//
//  CanvasView.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import SwiftUI

// MARK: - CanvasView

/// Interactive canvas for viewing images with zoom, pan, and drag-and-drop support.
public struct CanvasView: View {
    let image: NSImage?
    let isLoading: Bool

    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var lastDragPosition: CGSize = .zero

    public init(image: NSImage?, isLoading: Bool = false) {
        self.image = image
        self.isLoading = isLoading
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Neutral canvas viewport background
                Rectangle()
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                    .ignoresSafeArea()

                if let image = self.image {
                    // Image rendering inside canvas with subtle drop shadow
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .scaleEffect(self.zoomScale)
                        .offset(self.panOffset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    self.zoomScale = max(0.1, min(5.0, value))
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    self.panOffset = CGSize(
                                        width: self.lastDragPosition.width + value.translation.width,
                                        height: self.lastDragPosition.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    self.lastDragPosition = self.panOffset
                                }
                        )
                        .animation(.interactiveSpring(), value: self.zoomScale)
                } else if !self.isLoading {
                    // Elegant empty drop state card
                    VStack(spacing: DesignTokens.spacingMedium) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(.tint)

                        VStack(spacing: 4) {
                            Text("No Image Selected")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Drop an image file here or open from toolbar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                }

                if self.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
