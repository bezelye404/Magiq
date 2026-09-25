//
//  PixelWandWrapper.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Foundation

// MARK: - PixelWandWrapper

/// RAII wrapper around ImageMagick's `PixelWand*` C pointer.
///
/// Guarantees that `DestroyPixelWand` is invoked as soon as this object goes out of scope,
/// enforcing deterministic RAM discipline as mandated by AGENTS.md rule #4.
public final class PixelWandWrapper {
    public let pointer: OpaquePointer

    /// Initializes a new PixelWand.
    ///
    /// - Parameter color: Optional CSS/hex color string (e.g. "#FFFFFF", "none", "black").
    public init(color: String? = nil) throws {
        WandSession.shared.ensureInitialized()
        guard let ptr = NewPixelWand() else {
            throw MagickError.wandAllocationFailed
        }
        self.pointer = ptr

        if let color = color {
            let status = PixelSetColor(self.pointer, color)
            if status == MagickFalse {
                throw MagickError.operationFailed(operation: "PixelSetColor", reason: "Invalid color specification '\(color)'")
            }
        }
    }

    /// Sets the color string on the underlying pixel wand.
    public func setColor(_ color: String) -> Bool {
        return PixelSetColor(self.pointer, color) == MagickTrue
    }

    deinit {
        DestroyPixelWand(self.pointer)
    }
}
