//
//  MagickCLIExecutor.swift
//  Magiq
//
//  Created for Magiq - Native macOS ImageMagick GUI.
//

import Foundation

// MARK: - MagickCLIExecutor

/// Executes ImageMagick operations via the bundled CLI binary using `Process`.
///
/// **Architecture Justification (CLI Path):**
/// The CLI path is used for:
/// 1. One-off final exports to disk.
/// 2. Advanced delegate formats (e.g., Ghostscript PDF/PS, Raw camera profiles).
/// 3. Complex multi-stage commands or script files where full CLI coverage is required.
///
/// **Security Policy (AGENTS.md non-negotiable #6):**
/// Only argument arrays are used (`Process.arguments = [String]`). Never `/bin/sh -c` or shell strings.
public final class MagickCLIExecutor: Sendable {
    public static let shared = MagickCLIExecutor()

    private init() {}

    /// Resolves the filesystem path to the bundled or fallback `magick` executable.
    public func resolveExecutablePath() -> String {
        let bundle = Bundle.main
        if let resourcePath = bundle.resourcePath {
            let bundledBin = "\(resourcePath)/ImageMagickDistribution/bin/magick"
            if FileManager.default.isExecutableFile(atPath: bundledBin) {
                return bundledBin
            }
        }

        // Local development repository fallback
        let localBin = "\(FileManager.default.currentDirectoryPath)/Resources/ImageMagickDistribution/bin/magick"
        if FileManager.default.isExecutableFile(atPath: localBin) {
            return localBin
        }

        // System Homebrew fallback
        return "/opt/homebrew/bin/magick"
    }

    /// Resolves the directory housing ImageMagick resources.
    public func resolveDistributionPath() -> String {
        let bundle = Bundle.main
        if let resourcePath = bundle.resourcePath {
            let bundledDist = "\(resourcePath)/ImageMagickDistribution"
            if FileManager.default.fileExists(atPath: bundledDist) {
                return bundledDist
            }
        }
        return "\(FileManager.default.currentDirectoryPath)/Resources/ImageMagickDistribution"
    }

    /// Executes `magick` with the given argument array asynchronously.
    ///
    /// - Parameters:
    ///   - arguments: The array of command-line arguments (excluding the executable name).
    ///   - environment: Optional extra environment variables to merge.
    /// - Returns: A `MagickCLIResult` containing exit code, stdout, and stderr.
    public func execute(
        arguments: [String],
        environment: [String: String] = [:]
    ) async throws -> MagickCLIResult {
        let executablePath = self.resolveExecutablePath()
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            throw MagickError.fileNotFound(url: URL(fileURLWithPath: executablePath))
        }

        let distPath = self.resolveDistributionPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        // Scoped environment pointing to bundled libraries and modules
        var processEnv = ProcessInfo.processInfo.environment
        processEnv["MAGICK_HOME"] = distPath
        processEnv["MAGICK_CONFIGURE_PATH"] = "\(distPath)/etc/ImageMagick-7"
        processEnv["MAGICK_CODER_MODULE_PATH"] = "\(distPath)/modules/coders"
        processEnv["DYLD_LIBRARY_PATH"] = "\(distPath)/lib"

        for (key, val) in environment {
            processEnv[key] = val
        }
        process.environment = processEnv

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let startTime = CFAbsoluteTimeGetCurrent()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { proc in
                    let duration = CFAbsoluteTimeGetCurrent() - startTime
                    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                    let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                    let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                    let result = MagickCLIResult(
                        exitCode: proc.terminationStatus,
                        stdout: stdout,
                        stderr: stderr,
                        duration: duration
                    )

                    if proc.terminationStatus == 0 {
                        continuation.resume(returning: result)
                    } else {
                        continuation.resume(throwing: MagickError.cliExecutionFailed(
                            exitCode: proc.terminationStatus,
                            stderr: stderr
                        ))
                    }
                }

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            // Cancel background process immediately if parent Swift Task is cancelled
            if process.isRunning {
                process.terminate()
            }
        }
    }
}
