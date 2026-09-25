# ROADMAP.md

This tracks what's in scope now versus deferred. Anything not listed here should be discussed
before being built (see `AGENTS.md` → Non-negotiables → Scope discipline).

## Phase 0 — Foundation

- [x] Xcode project scaffold, SwiftUI app shell, `NavigationSplitView` layout per HIG.
- [x] Bundle a full-delegate ImageMagick distribution (CLI + dylibs) into the app; establish
  the update/rebuild process for that distribution.
- [x] `Core/MagickCore` interop layer (wand lifecycle wrappers, error mapping).
- [x] `Core/MagickCLI` process-invocation helper (argument-array based, no shell strings).
- [x] Basic single-image open → operation → export flow, exercising both integration paths.
- [x] App Sandbox entitlements + security-scoped bookmark handling.

## Phase 1 — Core feature set (approved for this pass)

- [ ] **Batch queue + folder watch**
  - Add multiple images / a watched folder.
  - Bounded worker pool for processing; visible per-item progress and errors.
  - Apply a preset or an ad-hoc operation chain across the batch.
- [ ] **Undo/redo history + preset profiles**
  - Non-destructive operation history per open document (lightweight, not full-buffer
    snapshots — see ARCHITECTURE.md RAM discipline).
  - Save an operation chain as a named preset; apply presets to single images or batches.
  - Built-in starter presets (e.g. "Web-optimized WebP", "HEIC → JPEG, max 2048px").
- [ ] **Quick Look extension**
  - `QLPreviewProvider` app extension so Finder can preview ImageMagick-supported formats
    that macOS doesn't natively render.
  - Ships as a separate, minimally-entitled extension target.

## Phase 2 — Polish

- [ ] Full HIG pass: motion (Reduce Motion support), Dynamic Type where applicable, VoiceOver
  labels, keyboard navigation, standard menu bar / toolbar conventions.
- [ ] Liquid Glass materials where the OS supports it, graceful fallback otherwise.
- [ ] Performance pass: RAM profiling under large batch jobs, thumbnail cache tuning.
- [ ] Localization scaffold (even if only English ships first).

## Considered, not currently in scope

These came up during planning but were **not selected** for the current pass. Listed here so
they aren't silently lost, and so no one builds them without a deliberate scope decision:

- Menu bar quick-access tool.
- Shortcuts app / App Intents integration.
- "Show equivalent ImageMagick command" / script export view.
- Any form of iCloud or other sync.
- Auto-update mechanism (see PRIVACY.md for the constraints it would need to meet).
- Intel Mac support (Apple Silicon is the initial target).

## Out of scope (by design)

- Any network-dependent feature that isn't strictly opt-in and disclosed in `PRIVACY.md`.
- Telemetry/analytics of any kind.
