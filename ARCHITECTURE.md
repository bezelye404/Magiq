# ARCHITECTURE.md

## Goals, in priority order

1. Full ImageMagick feature coverage — nothing a power user could do on the command line
   should be unreachable from the GUI.
2. Low steady-state RAM usage and high throughput on batch jobs.
3. A premium, native macOS feel: SwiftUI + AppKit, Apple HIG, system materials, smooth
   animations.
4. Zero network access, zero telemetry — privacy by construction, not by policy.

These sometimes pull in different directions (goal 1 wants "just shell out to the full CLI
for everything", goal 2 wants "avoid process spawn overhead"). The architecture below is the
resolution of that tension.

## ImageMagick integration: hybrid, and why

### The problem with "just link libMagickWand statically"

ImageMagick's real power comes from its delegates: libheif (HEIC/AVIF), LibRaw (camera RAW),
Ghostscript (PDF/PS), OpenJPEG (JPEG2000), Pango/FontConfig (text rendering), libwebp, and
dozens more. Statically linking `libMagickWand` alone gives you a small, "core-only" subset
of coders. Reproducing full CLI parity would mean manually vendoring and statically linking
every delegate library and keeping that in sync with upstream ImageMagick releases — high
maintenance burden, easy to silently lose a format or an option.

### The problem with "just shell out to the CLI for everything"

A bundled, fully-delegated `magick` CLI distribution (built the way Homebrew's formula does,
with every delegate enabled) gives 100% feature parity for free and is easy to keep up to
date by swapping the bundled distribution. But spawning a process for every thumbnail, every
live-preview redraw, and every batch-item status update is wasteful: process creation
overhead, no shared decode cache, harder to report fine-grained progress, and it works against
the low-RAM/high-throughput goal for hot paths.

### Resolution: two paths, one bundled distribution

Both paths use the **same bundled ImageMagick distribution** inside the app (CLI binaries +
shared libraries + delegate libraries), so there is only one thing to update and one licensing
surface to track.

| Path | Mechanism | Used for |
|---|---|---|
| **CLI path** | `Process` launching the bundled `magick` binary, argument arrays only | One-off exports, advanced/rare operations, anything exposed via a "raw command" power-user mode, operations with no clean C API equivalent (e.g. some `-script`/MSL usage) |
| **Linked path** | Swift/C interop calling `libMagickWand`/`libMagickCore` directly against the bundled dylibs | Thumbnails, live preview while adjusting parameters, batch-queue processing, undo/redo snapshot generation — anything called repeatedly per user session |

Rule of thumb encoded in `AGENTS.md`: **default to the linked path for anything invoked more
than once per user action; use the CLI path when it's genuinely a one-shot operation or the
feature has no practical C API equivalent.**

### RAM discipline on the linked path

- Every `MagickWand` (and related `PixelWand`/`DrawingWand`) is owned by a small RAII-style
  Swift wrapper whose `deinit` guarantees `DestroyMagickWand`/cleanup — no manual
  create/destroy pairs scattered through view models.
- Thumbnails are generated at bounded target resolutions (never "decode full image, then
  downscale") using ImageMagick's own resize-on-read facilities where available.
- A bounded LRU thumbnail/preview cache with an explicit memory budget, not an unbounded
  dictionary.
- Batch queue uses a fixed-size worker pool (`TaskGroup` with a semaphore or a bounded actor),
  so RAM usage is a function of worker count × per-image working set, not queue length.

## Module breakdown

- **Core/MagickCore** — the Swift/C interop layer: wand lifecycle wrappers, error mapping
  from ImageMagick's exception system to Swift `Error`, pixel/geometry helpers.
- **Core/MagickCLI** — process invocation helper: builds argument arrays (never strings),
  captures stdout/stderr, maps exit codes to Swift `Result`.
- **Core/ImagePipeline** — shared, path-agnostic abstractions (e.g. `ImageOperation`,
  `ImageOperationResult`) so UI/feature code doesn't need to know which path handled a
  given operation.
- **Features/BatchQueue** — queue model, bounded worker pool, folder-watch (via
  `DispatchSource` file system events / `FSEvents`, no polling), progress reporting.
- **Features/QuickLookExtension** — a `QLPreviewProvider` app extension target so Finder
  Quick Look can render formats ImageMagick supports but macOS doesn't natively. Runs in its
  own sandboxed extension process — keeps the main app's RAM profile unaffected by previews.
- **Features/History** — undo/redo stack. Stores lightweight operation descriptions + before
  references (not full-resolution duplicate buffers) so history doesn't balloon RAM.
- **Features/Presets** — named, reusable operation chains (e.g. "Web-optimized WebP",
  "HEIC → JPEG, max 2048px"), persisted locally.

## UI layer

- SwiftUI throughout, `NavigationSplitView` for the main window (sidebar: jobs/presets,
  detail: preview + inspector), matching HIG guidance for document/utility-style apps.
- System materials and, where the target OS supports it, the Liquid Glass design language
  (macOS 26+) for toolbars/sidebars — degrade gracefully to standard materials on older
  supported OS versions.
- Motion: SwiftUI's spring-based animations (`interactiveSpring`, `matchedGeometryEffect`
  for preview transitions), kept subtle and interruptible per HIG motion guidance; respect
  "Reduce Motion" accessibility setting.
- Full support for Dark/Light appearance, Dynamic Type where text is user-facing (not inside
  image canvases), and VoiceOver labels on all controls.

## Sandboxing & file access

- App Sandbox stays enabled. Folder-watch and batch-source folders are accessed via
  security-scoped bookmarks, requested through standard `NSOpenPanel`/drag-and-drop —
  never by broadening entitlements to bypass user consent.
- The Quick Look extension is a separate sandboxed target with its own, minimal entitlement
  set (read-only access to the file being previewed).

## Update mechanism (open question, not yet decided)

Sparkle is the common choice but performs an update-check network call by default, which
conflicts with the zero-network default. If auto-update is added later (see ROADMAP.md), it
must be: (a) off by default or clearly disclosed, (b) check-only (no background telemetry
payload), (c) documented in PRIVACY.md before it ships.
