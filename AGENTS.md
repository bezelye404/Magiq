# AGENTS.md

Instructions for AI coding agents (Claude Code, etc.) working in this repository.

## Project

**Magiq** *(working name — rename freely)* is a native macOS app (Apple Silicon first,
targeting macOS 15+/26) that provides a premium, HIG-compliant GUI for the full ImageMagick
feature set. It is open source and privacy-respecting: no network calls, no telemetry, ever.

## Tech stack — do not deviate without discussion

- **UI:** SwiftUI first, AppKit interop (`NSViewRepresentable`) only where SwiftUI cannot
  express something HIG requires (e.g. certain toolbar/sheet behaviors, `NSSavePanel` config).
- **ImageMagick integration — hybrid, by design (see ARCHITECTURE.md for full rationale):**
  1. **Bundled full `magick` CLI distribution** (all delegates: heif, raw, openjp2, pango,
     ghostscript, webp, etc.) invoked via `Process`, **argument arrays only — never
     `/bin/sh -c` or string-interpolated commands.** This is the path for full feature
     coverage: anything a user can type in an ImageMagick command line must be reachable.
  2. **Bundled `libMagickWand`/`libMagickCore` dylibs**, called directly through a Swift/C
     interop layer (`MagickCore` Swift module), for the hot path: thumbnails, live preview,
     batch processing progress, undo/redo snapshots. This avoids per-call process spawn
     overhead and keeps steady-state RAM low.
  3. New ImageMagick-facing code must state, in a comment, *why* it uses path (1) vs (2).
- **Concurrency:** Swift Concurrency (`async/await`, `TaskGroup`) with a **bounded** worker
  pool for batch jobs (default: `ProcessInfo.processInfo.activeProcessorCount`, user-tunable).
  Never spawn unbounded concurrent ImageMagick operations — this is the main RAM risk.
- **Persistence:** SwiftData (or plain JSON if SwiftData proves heavier than needed) for
  presets and undo/redo history metadata. No CloudKit/iCloud sync unless explicitly scoped
  and opt-in (see ROADMAP.md — not in current scope).
- **No third-party SDKs that phone home:** no analytics, no crash reporters that upload data,
  no auto-updaters that ping a server on every launch (if an updater is added later, it must
  be manual-check-only and disclosed in PRIVACY.md).

## Non-negotiables

1. **No network access** of any kind without an explicit, visible, opt-in UI control.
2. **No telemetry / analytics / crash reporting to third parties.**
3. App Sandbox entitlement stays **on**. File access via security-scoped bookmarks only.
   Never propose disabling sandboxing to "make something easier" — flag the blocker instead.
4. **RAM discipline:** release `MagickWand`/`Image` objects deterministically (RAII-style
   wrapper with `deinit` calling `DestroyMagickWand`/`MagickWandTerminus`), stream large
   files instead of loading full-resolution buffers into memory for preview, cap thumbnail
   cache size.
5. **HIG compliance:** use native SwiftUI controls, standard spacing/typography tokens,
   system materials (Liquid Glass where applicable on macOS 26+), SF Symbols, and platform-
   standard interactions (drag & drop, Quick Look, context menus, `NSToolbar`). No custom
   chrome unless HIG explicitly permits it for the control type in question.
6. **Security:** all ImageMagick invocations must validate/sanitize user-controlled input
   (filenames, geometry strings, text-annotation content). CLI path uses argument arrays;
   never build a command string. C API path uses ImageMagick's own escaping where applicable.
7. **Scope discipline:** check ROADMAP.md before adding a feature or dependency that isn't
   already listed. If it's not there, ask the human maintainer before building it.

## Directory structure (proposed — adjust as the project grows)

```
Magiq/
├── App/                    # App entry point, scene/window setup
├── Core/
│   ├── MagickCore/         # Swift/C interop layer over libMagickWand
│   ├── MagickCLI/          # Process-based invocation of bundled magick CLI
│   └── ImagePipeline/      # Shared abstractions used by both paths
├── Features/
│   ├── BatchQueue/         # Batch processing + folder watch
│   ├── QuickLookExtension/ # QLPreviewProvider app extension target
│   ├── History/            # Undo/redo stack
│   └── Presets/            # Preset profiles (store, editor)
├── UI/                     # SwiftUI views, view models, design tokens
├── Resources/
│   └── ImageMagickDistribution/  # Bundled magick CLI + dylibs + delegates
└── Tests/
```

## Build & test

*(Fill in once the Xcode project / SwiftPM setup exists — e.g. `xcodebuild -scheme Magiq
test`, `swift build`, `swiftlint`, `swiftformat --lint .`.)*

## Code style

- SwiftLint + SwiftFormat, enforced in CI (see CONTRIBUTING.md for exact rule set).
- Prefer value types; keep `MagickWand`-owning classes minimal and `final`.
- Document every public API with `///` doc comments.

## Where to look before making changes

- `ARCHITECTURE.md` — system design and the reasoning behind the hybrid ImageMagick strategy.
- `PRIVACY.md` — hard rules on data handling; nothing here is negotiable via a feature request.
- `ROADMAP.md` — what's in scope now vs. deferred.
- `CONTRIBUTING.md` — commit/PR conventions, local setup.

## Explicit agent rules

- Never introduce a dependency that performs network access or telemetry, even "just for
  crash reports" or "just for update checks" — flag it as a proposal instead of adding it.
- Never remove or weaken App Sandbox entitlements without explicitly surfacing this to the
  human maintainer in your response.
- Never use `/bin/sh -c` or string-built shell commands for ImageMagick invocation.
- When in doubt between the CLI path and the linked-library path, default to the linked
  library path for anything called more than once per user action.
- Keep PRs/diffs scoped to one feature or fix; don't opportunistically refactor unrelated code.
