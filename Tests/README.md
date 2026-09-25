# Tests/Fixtures/README.md

Manifest of where every test fixture comes from, why, and under what license.
Keep this updated whenever fixtures are added — it's the paper trail for
license compliance and for anyone wondering "why does this file exist".

None of these are fetched by the app at runtime. They exist purely for local
development and automated tests (see `AGENTS.md` → non-negotiables).

## `imagemagick/pseudo-images/`

**Source:** generated locally by the `magick` CLI itself, via
`fetch-imagemagick-samples.sh`. Not downloaded from anywhere — ImageMagick
generates these procedurally (`rose:`, `logo:`, `wizard:`, `granite:`,
`netscape:`, `gradient:`, `plasma:`, `radial-gradient:`).

**Why:** these are ImageMagick's own canonical built-in test images —
the most "authentic" possible smoke-test assets, and zero-network by nature.

**License:** part of the ImageMagick distribution itself (Apache 2.0 /
ImageMagick license — see the bundled distribution's own license file).

## `imagemagick/upstream-tests/`

**Source:** sparse git checkout of the `tests/` directory from
[ImageMagick/ImageMagick](https://github.com/ImageMagick/ImageMagick) on
GitHub, via `fetch-imagemagick-samples.sh`.

**Why:** the actual reference files ImageMagick's own test suite uses —
useful for regression coverage that mirrors upstream's own expectations.

**License:** ImageMagick project license — see the upstream repo's `LICENSE`
file at checkout time; re-verify if the fixture set is refreshed.

**Note:** upstream repo layout can change between ImageMagick releases —
if the script warns that `tests/` wasn't found where expected, check the
repo manually before assuming the fixture set is stale or missing.

## `picsum/` (from `fetch-fixtures.sh`)

**Source:** [picsum.photos](https://picsum.photos), various sizes/seeds/
variations (grayscale, blur, WebP).

**Why:** varied, realistic photographic content for thumbnail/preview/batch
UI testing — picsum only covers JPEG/WebP, so it does not substitute for
the format-specific fixtures below.

**License:** per picsum.photos' own terms — images are sourced from
Unsplash photographers; picsum is intended for development/testing use.
Do not ship these inside the app or any release artifact; dev/test only.

## RAW samples — not automated, manual step

**Source:** [raw.pixls.us](https://raw.pixls.us) — the community-maintained
successor to rawsamples.ch.

**Why:** real RAW sensor data (CR2/NEF/ARW/DNG/etc.) from many camera makes/
models, needed to exercise the RAW delegate path.

**License:** CC0 (public domain) for most files; a minority are
CC-BY-NC-SA — **check the license column on the site for each file you
download** and record it below if you add one.

**How to add:** browse raw.pixls.us, pick 2-3 files from different
manufacturers, drop them in `Tests/Fixtures/raw/`, and list them here:

| File | Camera | License | Added by |
|---|---|---|---|
| _(none yet)_ | | | |

## HEIC/HEIF samples — not automated, manual step

**Source:** your own device (AirDrop/cable a few photos from an iPhone to
the dev Mac). Third-party "HEIC sample" sites often serve re-encoded files
that don't reflect real device output.

**How to add:** drop files in `Tests/Fixtures/heic/`, note provenance here:

| File | Source | Added by |
|---|---|---|
| _(none yet)_ | | |

## Other formats — sources, not yet automated

| Format | Recommended source | Notes |
|---|---|---|
| Animated GIF | Wikimedia Commons, "Category:Animated GIF files" | free-licensed, varied frame counts |
| PSD | file-examples.com / filesamples.com, or Adobe's own samples | check per-file license/terms |
| PDF | file-examples.com, or any multi-page/vector+raster PDF | multi-page + mixed content tests the Ghostscript delegate best |
| SVG | [W3C SVG Test Suite](https://www.w3.org/Graphics/SVG/Test/) | good for edge cases: gradients, filters, clip-paths |
| ICO | iconarchive.com / file-examples.com | prefer multi-resolution ICOs (16–256px in one file) |
| Regression/benchmark sets | USC-SIPI Image Database, Kodak Lossless True Color Image Suite | stable, well-known references — good for pixel-exact diffing |

As these get added, follow the same pattern as the RAW/HEIC sections above:
a subfolder under `Tests/Fixtures/`, plus a small table here recording
source and license per file.
