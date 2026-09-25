//
//  MagickCLIExecutor.swift
//  Magiq
//

import Foundation

// MARK: - MagickCLIExecutor

/// Executes ImageMagick operations via the bundled CLI binary using Process.
///
/// **CLI Path Rationale:**
/// Used for one-off final exports, advanced delegate formats (PDF, RAW), and complex
/// operations where full CLI parity is needed. Uses argument arrays exclusively.
public final class MagickCLIExecutor: Sendable {
    public static let shared = MagickCLIExecutor()

    private init() {}

    // MARK: - Path Resolution

    public func resolveExecutablePath() -> String {
        let bundle = Bundle.main
        if let resourcePath = bundle.resourcePath {
            let bundledBin = "\(resourcePath)/ImageMagickDistribution/bin/magick"
            if FileManager.default.isExecutableFile(atPath: bundledBin) {
                return bundledBin
            }
        }

        let localBin = "\(FileManager.default.currentDirectoryPath)/Resources/ImageMagickDistribution/bin/magick"
        if FileManager.default.isExecutableFile(atPath: localBin) {
            return localBin
        }

        return "/opt/homebrew/bin/magick"
    }

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

    // MARK: - Process Execution

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
            if process.isRunning {
                process.terminate()
            }
        }
    }
}
