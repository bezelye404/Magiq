//
//  PixelWandWrapper.swift
//  Magiq
//

import Foundation

// MARK: - PixelWandWrapper

public final class PixelWandWrapper {
    public let pointer: OpaquePointer

    public init(color: String? = nil) throws {
        WandSession.shared.ensureInitialized()
        guard let ptr = NewPixelWand() else {
            throw MagickError.wandAllocationFailed
        }
        self.pointer = ptr

        if let color = color {
            let status = PixelSetColor(self.pointer, color)
            if status == MagickFalse {
                throw MagickError.operationFailed(operation: "PixelSetColor", reason: "Invalid color '\(color)'")
            }
        }
    }

    public func setColor(_ color: String) -> Bool {
        return PixelSetColor(self.pointer, color) == MagickTrue
    }

    deinit {
        DestroyPixelWand(self.pointer)
    }
}
