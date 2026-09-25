#!/bin/bash
#
# fetch-imagemagick-samples.sh
#
# Collects Magiq's test fixtures directly from ImageMagick itself:
#
#   1. Built-in procedural "pseudo-images" (rose:, logo:, wizard:, etc.) —
#      generated locally by the `magick` binary, zero network required.
#      These are literally shipped inside ImageMagick, so they're the most
#      "authentic" possible test assets.
#
#   2. A sparse git checkout of ImageMagick's own tests/ directory from its
#      official GitHub repo — the actual reference files its own test suite
#      uses for regression testing. Requires network + git, dev-time only
#      (same rule as fetch-fixtures.sh: never called by the app itself).
#
# Usage: ./fetch-imagemagick-samples.sh [output_dir]

set -euo pipefail

OUT_DIR="${1:-Tests/Fixtures/imagemagick}"
mkdir -p "$OUT_DIR/pseudo-images" "$OUT_DIR/upstream-tests"

# --- Part 1: built-in pseudo-images ------------------------------------
#
# Requires ImageMagick installed locally on the dev machine
# (e.g. `brew install imagemagick`) — this is separate from, and unrelated
# to, the distribution Magiq bundles inside the app itself.

if ! command -v magick &> /dev/null; then
  echo "ERROR: 'magick' CLI not found. Install it locally for this step:"
  echo "  brew install imagemagick"
  echo "(This is a dev-machine tool only — unrelated to the distribution"
  echo "Magiq bundles inside the app.)"
  exit 1
fi

echo "Generating built-in ImageMagick pseudo-images into $OUT_DIR/pseudo-images ..."

PSEUDO_DIR="$OUT_DIR/pseudo-images"

magick rose:                         "$PSEUDO_DIR/rose.png"
magick logo:                         "$PSEUDO_DIR/logo.png"
magick wizard:                       "$PSEUDO_DIR/wizard.png"
magick granite:                      "$PSEUDO_DIR/granite.png"
magick netscape:                     "$PSEUDO_DIR/netscape.png"
magick -size 400x300 gradient:       "$PSEUDO_DIR/gradient.png"
magick -size 400x300 plasma:fractal  "$PSEUDO_DIR/plasma.png"
magick -size 200x200 radial-gradient: "$PSEUDO_DIR/radial-gradient.png"

# A few useful transformed variants for filter/adjustment regression tests
magick "$PSEUDO_DIR/rose.png" -resize 400% "$PSEUDO_DIR/rose-upscaled.png"
magick "$PSEUDO_DIR/wizard.png" -colorspace Gray "$PSEUDO_DIR/wizard-grayscale.png"
magick "$PSEUDO_DIR/logo.png" -alpha set -channel A -evaluate set 50% \
  "$PSEUDO_DIR/logo-semitransparent.png"

echo "Pseudo-images done."

# --- Part 2: upstream test-suite reference files ------------------------
#
# Sparse-checkout of ImageMagick's own tests/ directory, straight from the
# project's GitHub repo. This is the real fixture set its own CI uses.

if ! command -v git &> /dev/null; then
  echo "WARNING: git not found, skipping upstream tests/ checkout."
  exit 0
fi

UPSTREAM_DIR="$OUT_DIR/upstream-tests"
TMP_CLONE=$(mktemp -d)
trap 'rm -rf "$TMP_CLONE"' EXIT

echo "Sparse-cloning ImageMagick/ImageMagick tests/ directory ..."

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/ImageMagick/ImageMagick.git "$TMP_CLONE"
(cd "$TMP_CLONE" && git sparse-checkout set tests)

if [ -d "$TMP_CLONE/tests" ]; then
  cp -R "$TMP_CLONE/tests/." "$UPSTREAM_DIR/"
  echo "Upstream tests/ copied into $UPSTREAM_DIR"
else
  echo "WARNING: tests/ directory not found at expected path — the"
  echo "upstream repo layout may have changed. Check manually at:"
  echo "  https://github.com/ImageMagick/ImageMagick/tree/main/tests"
fi

echo "Done."
