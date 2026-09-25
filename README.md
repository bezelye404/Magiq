# Magiq

A native, open-source macOS app that puts the full power of ImageMagick behind a premium,
Apple-HIG-compliant interface — without giving up performance or your privacy.

## Why

ImageMagick is enormously capable but lives on the command line. Magiq wraps it in a
SwiftUI/AppKit interface built the way a first-party Apple app would be: fast, low-memory,
native materials and motion, fully keyboard/VoiceOver accessible — while keeping 100% of
ImageMagick's feature surface reachable, not a stripped-down subset.

## Features

- **Full ImageMagick feature coverage** via a hybrid engine: a bundled, fully-delegated
  ImageMagick distribution for guaranteed feature parity, plus a directly linked
  `libMagickWand` path for fast, low-RAM thumbnails/previews/batch processing.
  See `ARCHITECTURE.md` for the full rationale.
- **Batch queue + folder watch** — point it at a folder, apply a preset, walk away.
- **Undo/redo history + preset profiles** — non-destructive editing, reusable operation
  chains for repeated workflows.
- **Quick Look extension** — preview ImageMagick-supported formats straight from Finder.
- **Zero network access, zero telemetry** — see `PRIVACY.md`.

## Requirements

- macOS 15+ (Apple Silicon).
- (Intel support not currently planned — see `ROADMAP.md`.)

## Building from source

*(fill in once the Xcode project exists — see `CONTRIBUTING.md` for the local setup steps.)*

## Project documentation

- [`AGENTS.md`](./AGENTS.md) — conventions and non-negotiables for anyone (human or AI agent)
  contributing code.
- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — system design, and why the ImageMagick integration
  is built the way it is.
- [`PRIVACY.md`](./PRIVACY.md) — exactly what the app does and doesn't do with your data.
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — how to set up, contribute, and submit PRs.
- [`ROADMAP.md`](./ROADMAP.md) — what's currently in scope, and what's deliberately deferred.

## License

*(choose and add a `LICENSE` file — e.g. MIT for this app's own code; note that the bundled
ImageMagick distribution and its delegate libraries retain their own upstream licenses.)*

## Status

Early planning / pre-implementation. Contributions and design feedback welcome — see
`CONTRIBUTING.md`.
# Magiq
