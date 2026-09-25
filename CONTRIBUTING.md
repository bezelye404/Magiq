# Contributing to Magiq

Thanks for considering a contribution. This project cares a lot about staying lightweight,
native, and privacy-respecting — please read `AGENTS.md` and `PRIVACY.md` before your first
PR; they encode the non-negotiables.

## Local setup

*(fill in once the Xcode project exists, e.g.:)*

1. Clone the repo.
2. `git submodule update --init` (if the bundled ImageMagick distribution is vendored as a
   submodule) or run the fetch script that downloads/builds the bundled distribution.
3. Open `Magiq.xcodeproj` (or `.xcworkspace`) in Xcode (latest stable).
4. Build & run the `Magiq` scheme on an Apple Silicon Mac.

## Requirements

- macOS 15+ (Apple Silicon; Intel support TBD — see ROADMAP.md).
- Xcode (latest stable at time of contribution).
- SwiftLint and SwiftFormat installed (`brew install swiftlint swiftformat`).

## Before you open a PR

- Run `swiftformat .` and `swiftlint` — CI will fail on violations.
- Add/update tests for any behavior change under `Tests/`.
- If you touch ImageMagick invocation code, confirm in your PR description whether you used
  the CLI path or the linked-library path, and why (see `ARCHITECTURE.md`).
- If you add a dependency, confirm it makes no network calls and collects no telemetry —
  state this explicitly in the PR description.
- Keep PRs scoped to a single feature or fix. Large, multi-concern PRs will be asked to split.

## Commit messages

Conventional, imperative mood, scoped when helpful:

```
feat(batch-queue): add bounded worker pool for folder watch
fix(magickcore): release wand on early-exit path
docs(architecture): clarify CLI vs linked-library rule of thumb
```

## Branching

- `main` is always releasable.
- Feature branches: `feature/<short-name>`, fix branches: `fix/<short-name>`.
- Rebase on `main` before requesting review; keep history reasonably clean (squash trivial
  fixup commits).

## Code review expectations

- At least one approving review before merge.
- CI (lint + tests) must pass.
- Reviewers will check PRs against `AGENTS.md`'s non-negotiables (sandboxing, no network
  calls, RAM discipline, HIG compliance) — not just correctness.

## Reporting bugs / privacy issues

- General bugs: open a GitHub issue with repro steps, macOS version, and chip (Apple Silicon
  generation).
- If you believe you've found a privacy violation (e.g. an unexpected network call), please
  flag it as high priority in the issue title — this project treats that as a serious bug,
  not just a feature gap.

## License

By contributing, you agree your contributions are licensed under the project's license (see
`LICENSE`). Note that bundled ImageMagick components retain their own upstream licenses.
