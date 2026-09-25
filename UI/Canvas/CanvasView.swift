//
//  CanvasView.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import SwiftUI

// MARK: - CanvasView

/// Interactive canvas for viewing images with zoom, pan, and drop support.
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
                // Background subtle checkerboard or dark/light canvas
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()

                if let image = self.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
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
                    // Placeholder when no image is loaded
                    VStack(spacing: DesignTokens.spacingMedium) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.secondary)

                        Text("Drop an image here or open from toolbar")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                if self.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial.opacity(0.6))
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: self.zoomOut) {
                        Label("Zoom Out", systemImage: "minus.magnifyingglass")
                    }
                    .keyboardShortcut("-", modifiers: .command)

                    Button(action: self.resetZoom) {
                        Label("Actual Size", systemImage: "1.magnifyingglass")
                    }
                    .keyboardShortcut("0", modifiers: .command)

                    Button(action: self.zoomIn) {
                        Label("Zoom In", systemImage: "plus.magnifyingglass")
                    }
                    .keyboardShortcut("+", modifiers: .command)
                }
            }
        }
    }

    private func zoomIn() {
        self.zoomScale = min(5.0, self.zoomScale * 1.25)
    }

    private func zoomOut() {
        self.zoomScale = max(0.1, self.zoomScale * 0.8)
    }

    private func resetZoom() {
        self.zoomScale = 1.0
        self.panOffset = .zero
        self.lastDragPosition = .zero
    }
}
