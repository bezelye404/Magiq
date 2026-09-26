//
//  PreviewProvider.swift
//  Magiq
//

import AppKit
import Foundation
import QuickLookUI

/// Modern Quick Look Preview Provider powered by ImageMagick.
/// Renders bounded previews for all formats supported by Magiq (RAW, WebP, AVIF, TIFF, PDF, ICO, etc.)
/// with deterministic RAM discipline (<30 MB peak).
public final class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    public func providePreview(for request: QLFilePreviewRequest, completionHandler: @escaping (QLPreviewReply?, (any Error)?) -> Void) {
        let fileURL = request.fileURL
        let maxDimension: CGFloat = 1024

        do {
            // 1. Inspect image dimensions using MagickPingImage without allocating pixel buffer
            let meta = try ImageWand.pingMetadata(from: fileURL)
            let originalWidth = CGFloat(max(1, meta.width))
            let originalHeight = CGFloat(max(1, meta.height))
            let aspect = originalWidth / originalHeight

            let targetWidth: CGFloat
            let targetHeight: CGFloat
            if aspect >= 1.0 {
                targetWidth = min(maxDimension, originalWidth)
                targetHeight = max(1, (targetWidth / aspect).rounded())
            } else {
                targetHeight = min(maxDimension, originalHeight)
                targetWidth = max(1, (targetHeight * aspect).rounded())
            }

            let contextSize = CGSize(width: targetWidth, height: targetHeight)

            // 2. Stream bounded thumbnail into drawing context
            let reply = QLPreviewReply(contextSize: contextSize, isBitmap: true) { context, _ in
                autoreleasepool {
                    do {
                        let wand = try ImageWand()
                        try wand.readThumbnail(
                            from: fileURL,
                            pageIndex: 0,
                            maxBounds: MagickGeometry(width: Int(targetWidth), height: Int(targetHeight))
                        )

                        guard let nsImage = wand.makeNSImage(),
                              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                            return
                        }

                        let rect = CGRect(origin: .zero, size: contextSize)
                        context.draw(cgImage, in: rect)
                    } catch {
                        // Silently fail drawing so Finder renders standard fallback preview
                    }
                }
            }
            completionHandler(reply, nil)
        } catch {
            completionHandler(nil, error)
        }
    }
}
