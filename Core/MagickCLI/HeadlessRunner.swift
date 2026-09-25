//
//  HeadlessRunner.swift
//  Magiq
//

import Foundation

// MARK: - HeadlessRunner

/// Headless execution engine enabling macOS Quick Actions, Shortcuts, and Terminal automation.
public enum HeadlessRunner {

    public static func isHeadlessInvocation() -> Bool {
        return CommandLine.arguments.contains("--convert") || CommandLine.arguments.contains("-c")
    }

    /// Executes headless conversion and exits the process when finished.
    public static func runIfHeadless() {
        guard self.isHeadlessInvocation() else { return }

        let args = CommandLine.arguments
        guard let convertIdx = args.firstIndex(where: { $0 == "--convert" || $0 == "-c" }),
              convertIdx + 1 < args.count else {
            print("Error: Missing input file path after --convert")
            exit(1)
        }

        let inputPath = args[convertIdx + 1]
        let inputURL = URL(fileURLWithPath: inputPath)

        var targetFormat = "WEBP"
        if let formatIdx = args.firstIndex(of: "--format"), formatIdx + 1 < args.count {
            targetFormat = args[formatIdx + 1].uppercased()
        }

        var quality = 85
        if let qIdx = args.firstIndex(of: "--quality"), qIdx + 1 < args.count,
           let parsedQ = Int(args[qIdx + 1]) {
            quality = max(1, min(100, parsedQ))
        }

        var outputURL: URL
        if let outIdx = args.firstIndex(of: "--out"), outIdx + 1 < args.count {
            outputURL = URL(fileURLWithPath: args[outIdx + 1])
        } else {
            let base = inputURL.deletingPathExtension()
            outputURL = base.appendingPathExtension(targetFormat.lowercased())
        }

        WandSession.shared.ensureInitialized()

        final class ResultBox: @unchecked Sendable {
            var code: Int32 = 0
        }
        let box = ResultBox()
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                let ops: [any ImageOperation] = [
                    FormatConvertOperation(format: targetFormat, quality: quality)
                ]
                _ = try await ImagePipeline.shared.export(from: inputURL, to: outputURL, operations: ops)
                print("Magiq: Successfully converted '\(inputURL.lastPathComponent)' -> '\(outputURL.path)'")
                box.code = 0
            } catch {
                print("Magiq: Conversion failed - \(error.localizedDescription)")
                box.code = 1
            }
            semaphore.signal()
        }

        semaphore.wait()
        exit(box.code)
    }
}
