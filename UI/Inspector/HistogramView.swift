//
//  HistogramView.swift
//  Magiq
//

import SwiftUI

// MARK: - HistogramChannel

public enum HistogramChannel: String, CaseIterable, Identifiable {
    case rgb = "RGB"
    case luminance = "Luma"
    case red = "Red"
    case green = "Green"
    case blue = "Blue"

    public var id: String { self.rawValue }
}

// MARK: - HistogramView

public struct HistogramView: View {
    public let data: HistogramData?
    public let isProcessing: Bool
    @State private var selectedChannel: HistogramChannel = .rgb

    public init(data: HistogramData?, isProcessing: Bool = false) {
        self.data = data
        self.isProcessing = isProcessing
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Channel Selector Header with Zero Layout Shift Live Status
            HStack(spacing: 6) {
                Label("Histogram", systemImage: "chart.bar.xaxis")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                if self.isProcessing {
                    HStack(spacing: 3) {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 10, height: 10)
                        Text("Live")
                            .font(.caption2.bold())
                            .foregroundStyle(.tint)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                    .transition(.opacity)
                }

                Spacer()

                Picker("Channel", selection: self.$selectedChannel) {
                    ForEach(HistogramChannel.allCases) { channel in
                        Text(channel.rawValue).tag(channel)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.mini)
                .frame(width: 160)
            }
            .animation(.easeInOut(duration: 0.15), value: self.isProcessing)

            // Graph Area
            ZStack(alignment: .bottomLeading) {
                // Background & Grid Lines
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                // Grid divisions (25%, 50%, 75%)
                GeometryReader { geo in
                    Path { path in
                        let w = geo.size.width
                        let h = geo.size.height
                        // Vertical grid lines
                        path.move(to: CGPoint(x: w * 0.25, y: 0))
                        path.addLine(to: CGPoint(x: w * 0.25, y: h))
                        path.move(to: CGPoint(x: w * 0.5, y: 0))
                        path.addLine(to: CGPoint(x: w * 0.5, y: h))
                        path.move(to: CGPoint(x: w * 0.75, y: 0))
                        path.addLine(to: CGPoint(x: w * 0.75, y: h))
                    }
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                }

                // Channel Paths
                if let hist = self.data {
                    GeometryReader { geo in
                        let size = geo.size
                        switch self.selectedChannel {
                        case .rgb:
                            self.channelPath(bins: hist.red, size: size)
                                .fill(Color.red.opacity(0.35))
                            self.channelPath(bins: hist.green, size: size)
                                .fill(Color.green.opacity(0.35))
                            self.channelPath(bins: hist.blue, size: size)
                                .fill(Color.blue.opacity(0.35))
                        case .luminance:
                            self.channelPath(bins: hist.luminance, size: size)
                                .fill(LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        case .red:
                            self.channelPath(bins: hist.red, size: size)
                                .fill(Color.red.opacity(0.55))
                        case .green:
                            self.channelPath(bins: hist.green, size: size)
                                .fill(Color.green.opacity(0.55))
                        case .blue:
                            self.channelPath(bins: hist.blue, size: size)
                                .fill(Color.blue.opacity(0.55))
                        }
                    }
                } else {
                    Text("No image data")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Clipping Indicators
                if let hist = self.data {
                    HStack {
                        if hist.shadowClipping > 0.01 {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                                .help(String(format: "Shadow clipping: %.1f%%", hist.shadowClipping * 100))
                                .padding(4)
                        }

                        Spacer()

                        if hist.highlightClipping > 0.01 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                                .help(String(format: "Highlight clipping: %.1f%%", hist.highlightClipping * 100))
                                .padding(4)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(height: 75)
        }
    }

    private func channelPath(bins: [Float], size: CGSize) -> Path {
        var path = Path()
        guard bins.count > 1 else { return path }

        let stepX = size.width / CGFloat(bins.count - 1)
        path.move(to: CGPoint(x: 0, y: size.height))

        for (index, val) in bins.enumerated() {
            let x = CGFloat(index) * stepX
            let y = size.height * (1.0 - CGFloat(min(1.0, max(0.0, val))))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }
}
