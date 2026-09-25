//
//  CropOverlayView.swift
//  Magiq
//

import SwiftUI

// MARK: - CropAspectRatio

public enum CropAspectRatio: String, CaseIterable, Identifiable {
    case free = "Free"
    case square = "1:1"
    case portrait45 = "4:5"
    case landscape169 = "16:9"
    case photo32 = "3:2"
    case story916 = "9:16"

    public var id: String { self.rawValue }

    public var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .portrait45: return 4.0 / 5.0
        case .landscape169: return 16.0 / 9.0
        case .photo32: return 3.0 / 2.0
        case .story916: return 9.0 / 16.0
        }
    }
}

// MARK: - CropOverlayView

public struct CropOverlayView: View {
    public let imageSize: CGSize
    public let onApply: (CGRect) -> Void
    public let onCancel: () -> Void

    @State private var selectedRatio: CropAspectRatio = .free
    @State private var cropRect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)

    public init(
        imageSize: CGSize,
        onApply: @escaping (CGRect) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.imageSize = imageSize
        self.onApply = onApply
        self.onCancel = onCancel
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let currentPx = CGRect(
                x: self.cropRect.origin.x * w,
                y: self.cropRect.origin.y * h,
                width: self.cropRect.size.width * w,
                height: self.cropRect.size.height * h
            )

            ZStack {
                // Dimmed exterior mask
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geo.size))
                    path.addRect(currentPx)
                }
                .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))

                // Crop border & Rule-of-Thirds Grid
                Path { path in
                    path.addRect(currentPx)

                    // 1/3 and 2/3 vertical lines
                    let x1 = currentPx.minX + currentPx.width / 3.0
                    let x2 = currentPx.minX + (currentPx.width * 2.0) / 3.0
                    path.move(to: CGPoint(x: x1, y: currentPx.minY))
                    path.addLine(to: CGPoint(x: x1, y: currentPx.maxY))
                    path.move(to: CGPoint(x: x2, y: currentPx.minY))
                    path.addLine(to: CGPoint(x: x2, y: currentPx.maxY))

                    // 1/3 and 2/3 horizontal lines
                    let y1 = currentPx.minY + currentPx.height / 3.0
                    let y2 = currentPx.minY + (currentPx.height * 2.0) / 3.0
                    path.move(to: CGPoint(x: currentPx.minX, y: y1))
                    path.addLine(to: CGPoint(x: currentPx.maxX, y: y1))
                    path.move(to: CGPoint(x: currentPx.minX, y: y2))
                    path.addLine(to: CGPoint(x: currentPx.maxX, y: y2))
                }
                .stroke(Color.white.opacity(0.8), lineWidth: 1.5)

                // 4 Corner Handles
                self.cornerHandle(x: currentPx.minX, y: currentPx.minY) { d in
                    self.adjustCrop(deltaX: d.width / w, deltaY: d.height / h, anchor: .topLeft)
                }
                self.cornerHandle(x: currentPx.maxX, y: currentPx.minY) { d in
                    self.adjustCrop(deltaX: d.width / w, deltaY: d.height / h, anchor: .topRight)
                }
                self.cornerHandle(x: currentPx.minX, y: currentPx.maxY) { d in
                    self.adjustCrop(deltaX: d.width / w, deltaY: d.height / h, anchor: .bottomLeft)
                }
                self.cornerHandle(x: currentPx.maxX, y: currentPx.maxY) { d in
                    self.adjustCrop(deltaX: d.width / w, deltaY: d.height / h, anchor: .bottomRight)
                }

                // Center Drag Gesture to move the box
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: max(0, currentPx.width - 40), height: max(0, currentPx.height - 40))
                    .position(x: currentPx.midX, y: currentPx.midY)
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                let dx = val.translation.width / w
                                let dy = val.translation.height / h
                                let newX = max(0.0, min(1.0 - self.cropRect.width, self.cropRect.minX + dx * 0.05))
                                let newY = max(0.0, min(1.0 - self.cropRect.height, self.cropRect.minY + dy * 0.05))
                                self.cropRect.origin = CGPoint(x: newX, y: newY)
                            }
                    )

                // Top Toolbar: Aspect Ratios and Buttons
                VStack {
                    HStack(spacing: 12) {
                        Picker("Ratio", selection: self.$selectedRatio) {
                            ForEach(CropAspectRatio.allCases) { r in
                                Text(r.rawValue).tag(r)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 280)
                        .onChange(of: self.selectedRatio) { _, newRatio in
                            self.applyAspectRatio(newRatio)
                        }

                        Spacer()

                        Button("Cancel", role: .cancel) {
                            self.onCancel()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("Apply Crop") {
                            self.onApply(self.cropRect)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                    .padding(.top, 16)

                    Spacer()
                }
            }
        }
    }

    // MARK: - Handles & Adjustments

    private enum Anchor { case topLeft, topRight, bottomLeft, bottomRight }

    private func cornerHandle(x: CGFloat, y: CGFloat, onDrag: @escaping (CGSize) -> Void) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 14, height: 14)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.4), lineWidth: 1))
            .shadow(radius: 2)
            .position(x: x, y: y)
            .gesture(
                DragGesture()
                    .onChanged { val in
                        onDrag(val.translation)
                    }
            )
    }

    private func adjustCrop(deltaX: CGFloat, deltaY: CGFloat, anchor: Anchor) {
        var rect = self.cropRect
        let scale: CGFloat = 0.05

        switch anchor {
        case .topLeft:
            rect.origin.x = max(0.0, min(rect.maxX - 0.1, rect.origin.x + deltaX * scale))
            rect.origin.y = max(0.0, min(rect.maxY - 0.1, rect.origin.y + deltaY * scale))
            rect.size.width = self.cropRect.maxX - rect.origin.x
            rect.size.height = self.cropRect.maxY - rect.origin.y
        case .topRight:
            rect.origin.y = max(0.0, min(rect.maxY - 0.1, rect.origin.y + deltaY * scale))
            rect.size.width = max(0.1, min(1.0 - rect.origin.x, rect.size.width + deltaX * scale))
            rect.size.height = self.cropRect.maxY - rect.origin.y
        case .bottomLeft:
            rect.origin.x = max(0.0, min(rect.maxX - 0.1, rect.origin.x + deltaX * scale))
            rect.size.width = self.cropRect.maxX - rect.origin.x
            rect.size.height = max(0.1, min(1.0 - rect.origin.y, rect.size.height + deltaY * scale))
        case .bottomRight:
            rect.size.width = max(0.1, min(1.0 - rect.origin.x, rect.size.width + deltaX * scale))
            rect.size.height = max(0.1, min(1.0 - rect.origin.y, rect.size.height + deltaY * scale))
        }

        self.cropRect = rect
    }

    private func applyAspectRatio(_ ratio: CropAspectRatio) {
        guard let r = ratio.ratio else { return }
        var rect = self.cropRect
        let newHeight = rect.width / r
        if rect.origin.y + newHeight <= 1.0 {
            rect.size.height = newHeight
        } else {
            rect.size.height = 1.0 - rect.origin.y
            rect.size.width = rect.size.height * r
        }
        self.cropRect = rect
    }
}
