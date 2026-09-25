//
//  CanvasView.swift
//  Magiq
//

import SwiftUI

// MARK: - CanvasView

public struct CanvasView: View {
    let image: NSImage?
    let originalImage: NSImage?
    let metadata: ImageMetadata?
    let isLoading: Bool

    @Binding var isCropping: Bool
    @Binding var isLoupeActive: Bool
    let onApplyCrop: ((CGRect) -> Void)?

    @ObservedObject private var settings = UserSettings.shared
    @ObservedObject private var shortcuts = KeyboardShortcutManager.shared

    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var lastDragPosition: CGSize = .zero
    @State private var compareMode: Bool = false
    @State private var splitPosition: CGFloat = 0.5
    @State private var hoverPoint: CGPoint = .zero
    @State private var isHovering: Bool = false

    public init(
        image: NSImage?,
        originalImage: NSImage? = nil,
        metadata: ImageMetadata? = nil,
        isLoading: Bool = false,
        isCropping: Binding<Bool> = .constant(false),
        isLoupeActive: Binding<Bool> = .constant(false),
        onApplyCrop: ((CGRect) -> Void)? = nil
    ) {
        self.image = image
        self.originalImage = originalImage
        self.metadata = metadata
        self.isLoading = isLoading
        self._isCropping = isCropping
        self._isLoupeActive = isLoupeActive
        self.onApplyCrop = onApplyCrop
    }

    public var body: some View {
        GeometryReader { outerGeo in
            ZStack {
                // Background layer
                self.canvasBackgroundView

                if let currentImage = self.image {
                    ZStack {
                        if self.compareMode, let original = self.originalImage {
                            self.splitCompareView(
                                original: original,
                                edited: currentImage,
                                containerSize: outerGeo.size
                            )
                        } else {
                            Image(nsImage: currentImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .contentTransition(.opacity)
                                .animation(.easeInOut(duration: 0.12), value: currentImage)
                        }
                    }
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                    .scaleEffect(self.zoomScale)
                    .offset(self.panOffset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                guard !self.isCropping else { return }
                                self.zoomScale = max(0.1, min(5.0, value))
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                guard !self.compareMode, !self.isCropping else { return }
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
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            self.hoverPoint = location
                            self.isHovering = true
                        case .ended:
                            self.isHovering = false
                        }
                    }

                    // Feature 6: Interactive Pixel Loupe
                    if self.isLoupeActive && self.isHovering {
                        LoupeView(
                            image: currentImage,
                            targetPoint: self.hoverPoint,
                            viewSize: outerGeo.size,
                            magnification: 3.0
                        )
                    }

                    // Feature 2: Interactive Crop Overlay
                    if self.isCropping {
                        CropOverlayView(
                            imageSize: outerGeo.size,
                            onApply: { rect in
                                self.onApplyCrop?(rect)
                                self.isCropping = false
                            },
                            onCancel: {
                                self.isCropping = false
                            }
                        )
                    }

                    // Top Metadata HUD
                    if let meta = self.metadata, !self.isCropping {
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    Label(meta.dimensionsString, systemImage: "aspectratio")
                                    Divider().frame(height: 12)
                                    Text(meta.format).bold()
                                    Divider().frame(height: 12)
                                    Text(meta.colorspace)
                                    if let size = meta.fileSizeFormatted {
                                        Divider().frame(height: 12)
                                        Text(size)
                                    }
                                }
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                                .padding(.top, 14)
                                .padding(.trailing, 16)
                            }
                            Spacer()
                        }
                    }

                    // Bottom Floating Control Island
                    if !self.isCropping {
                        VStack {
                            Spacer()
                            HStack(spacing: 12) {
                                Button(action: self.zoomOut) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .help("Zoom Out (\(self.shortcuts.shortcut(for: .zoomOut).displayString))")

                                Button(action: self.resetZoom) {
                                    Text("\(Int(self.zoomScale * 100))%")
                                        .font(.caption.monospacedDigit())
                                        .bold()
                                }
                                .buttonStyle(.plain)
                                .help("Actual Size (\(self.shortcuts.shortcut(for: .zoomFit).displayString))")

                                Button(action: self.zoomIn) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .help("Zoom In (\(self.shortcuts.shortcut(for: .zoomIn).displayString))")

                                Divider().frame(height: 14)

                                // Pixel Loupe Button (Feature 6)
                                Button(action: { self.isLoupeActive.toggle() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "magnifyingglass.circle")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text("Loupe")
                                            .font(.caption2.weight(.medium))
                                    }
                                    .foregroundStyle(self.isLoupeActive ? Color.accentColor : Color.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Toggle Pixel Magnifier Loupe")

                                // Crop Tool Button (Feature 2)
                                Button(action: { self.isCropping = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crop")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text("Crop")
                                            .font(.caption2.weight(.medium))
                                    }
                                    .foregroundStyle(Color.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Open Interactive Crop Tool")

                                if self.originalImage != nil {
                                    Divider().frame(height: 14)

                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            self.compareMode.toggle()
                                            if self.compareMode {
                                                self.resetZoom()
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "rectangle.split.2x1")
                                                .font(.system(size: 11, weight: .semibold))
                                            Text("Compare")
                                                .font(.caption2.weight(.medium))
                                        }
                                        .foregroundStyle(self.compareMode ? Color.accentColor : Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Toggle Before / After Split View (\(self.shortcuts.shortcut(for: .toggleCompare).displayString))")
                                }

                                Divider().frame(height: 14)

                                // Background toggle
                                Menu {
                                    Button("Neutral Dark") { self.settings.canvasBackground = "Neutral Dark" }
                                    Button("Subtle Checkerboard") { self.settings.canvasBackground = "Subtle Checkerboard" }
                                    Button("Solid Black") { self.settings.canvasBackground = "Solid Black" }
                                    Button("System") { self.settings.canvasBackground = "System" }
                                } label: {
                                    Image(systemName: "paintpalette")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .menuStyle(.borderlessButton)
                                .help("Canvas Background")
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

                // Non-blocking live rendering indicator when image is already loaded
                if self.isLoading && self.image != nil {
                    VStack {
                        HStack {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.65)
                                    .frame(width: 14, height: 14)
                                Text("Rendering...")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            .padding(.top, 14)
                            .padding(.leading, 16)

                            Spacer()
                        }
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if self.isLoading {
                    // Initial load spinner
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
                    .keyboardShortcut(
                        self.shortcuts.shortcut(for: .zoomIn).keyEquivalent,
                        modifiers: self.shortcuts.shortcut(for: .zoomIn).eventModifiers
                    )
                Button(action: self.zoomOut) { EmptyView() }
                    .keyboardShortcut(
                        self.shortcuts.shortcut(for: .zoomOut).keyEquivalent,
                        modifiers: self.shortcuts.shortcut(for: .zoomOut).eventModifiers
                    )
                Button(action: self.resetZoom) { EmptyView() }
                    .keyboardShortcut(
                        self.shortcuts.shortcut(for: .zoomFit).keyEquivalent,
                        modifiers: self.shortcuts.shortcut(for: .zoomFit).eventModifiers
                    )
                Button(action: { self.compareMode.toggle() }) { EmptyView() }
                    .keyboardShortcut(
                        self.shortcuts.shortcut(for: .toggleCompare).keyEquivalent,
                        modifiers: self.shortcuts.shortcut(for: .toggleCompare).eventModifiers
                    )
            }
            .opacity(0)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var canvasBackgroundView: some View {
        switch self.settings.canvasBackground {
        case "Subtle Checkerboard":
            CheckerboardView()
                .ignoresSafeArea()
        case "Solid Black":
            Color.black
                .ignoresSafeArea()
        case "Neutral Dark":
            Color(nsColor: .controlBackgroundColor).opacity(0.4)
                .ignoresSafeArea()
        default:
            Color.clear
                .ignoresSafeArea()
        }
    }

    private func splitCompareView(
        original: NSImage,
        edited: NSImage,
        containerSize: CGSize
    ) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let splitX = width * self.splitPosition

            ZStack(alignment: .leading) {
                // Left side: Original Image
                Image(nsImage: original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)

                // Right side: Edited Image (masked to right portion)
                Image(nsImage: edited)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)
                    .mask(
                        HStack(spacing: 0) {
                            Spacer()
                                .frame(width: splitX)
                            Rectangle()
                                .frame(width: max(0, width - splitX))
                        }
                    )

                // Divider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .offset(x: splitX - 1)
                    .shadow(color: .black.opacity(0.5), radius: 2)

                // Center handle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.8), lineWidth: 1.5))
                    .overlay(
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.primary)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 4)
                    .position(x: splitX, y: height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                let clamped = max(0.02, min(0.98, val.location.x / width))
                                self.splitPosition = clamped
                            }
                    )

                // Labels
                VStack {
                    HStack {
                        Text("Original")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.leading, 12)

                        Spacer()

                        Text("Edited")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.trailing, 12)
                    }
                    .padding(.top, 12)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Zoom & Pan Actions

    private func zoomIn() {
        self.zoomScale = min(5.0, self.zoomScale * self.settings.zoomSensitivity)
    }

    private func zoomOut() {
        self.zoomScale = max(0.1, self.zoomScale / self.settings.zoomSensitivity)
    }

    private func resetZoom() {
        self.zoomScale = 1.0
        self.panOffset = .zero
        self.lastDragPosition = .zero
    }
}
