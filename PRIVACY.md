# PRIVACY.md

Magiq is built on one simple rule: **your images and your data never leave your Mac
unless you explicitly export them somewhere yourself.**

## What we collect

Nothing. There is no analytics SDK, no crash reporter that uploads data, no telemetry of any
kind built into this application.

## Network access

The app makes **zero network requests** in its default configuration. There is no "phone
home" on launch, no update-check ping, no usage-statistics beacon. If an optional, opt-in
auto-update mechanism is ever added, it will:

- be off by default,
- only ever check "is there a newer version," nothing else,
- be clearly disclosed here and in the app's settings before it ships,
- never transmit anything about the images you work with.

## File access

Magiq uses macOS App Sandbox. It can only read or write files you explicitly grant
access to — by opening them, dragging them in, or choosing a folder to watch for batch
processing. This access is implemented via security-scoped bookmarks, the standard, revocable
mechanism Apple provides; you can always see and revoke this access in System Settings.

Batch "folder watch" only observes folders you have explicitly selected, and only for the
purpose of detecting new/changed files to process locally — nothing about folder contents is
sent anywhere.

## Local storage

Presets, undo/redo history metadata, and app preferences are stored locally on your Mac
(e.g. in `~/Library/Application Support/Magiq` or via SwiftData's local store). None
of this syncs anywhere unless you explicitly enable a sync feature in the future, which would
be opt-in and documented here first.

## Third-party components

- **ImageMagick** and its bundled delegate libraries are used entirely locally for image
  processing. See their respective licenses in `THIRD_PARTY_LICENSES` (to be added as
  dependencies are finalized).
- No third-party SDKs that collect data are included. If a dependency is ever added that has
  its own network or data-collection behavior, it will be disclosed here before release, and
  we will prefer forks/configurations with that behavior disabled where possible.

## Open source

The full source is available for inspection — every claim in this document is verifiable by
reading the code. If you find a discrepancy between this document and actual behavior, please
open an issue; that's a bug we consider high priority.

## Questions

Open an issue in the repository if anything here is unclear or if you'd like clarification on
a specific permission the app requests.
