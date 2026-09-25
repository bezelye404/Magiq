//
//  CanvasView.swift
//  Magiq
//

import SwiftUI

// MARK: - CanvasView

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
        GeometryReader { _ in
            ZStack {
                Rectangle()
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                    .ignoresSafeArea()

                if let image = self.image {
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

                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: self.zoomOut) {
                                Image(systemName: "minus")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.plain)
                            .help("Zoom Out (⌘-)")

                            Button(action: self.resetZoom) {
                                Text("\(Int(self.zoomScale * 100))%")
                                    .font(.caption.monospacedDigit())
                                    .bold()
                            }
                            .buttonStyle(.plain)
                            .help("Actual Size (⌘0)")

                            Button(action: self.zoomIn) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.plain)
                            .help("Zoom In (⌘+)")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                        .padding(.bottom, 16)
                    }
                } else if !self.isLoading {
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
        .background {
            Group {
                Button(action: self.zoomIn) { EmptyView() }
                    .keyboardShortcut("+", modifiers: .command)
                Button(action: self.zoomOut) { EmptyView() }
                    .keyboardShortcut("-", modifiers: .command)
                Button(action: self.resetZoom) { EmptyView() }
                    .keyboardShortcut("0", modifiers: .command)
            }
            .opacity(0)
        }
    }

    // MARK: - Zoom & Pan Actions

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
