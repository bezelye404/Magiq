#!/usr/bin/env bash
# ==============================================================================
# bundle_imagemagick.sh
# Bundles ImageMagick CLI, core dylibs, coder modules, and config XMLs into
# Resources/ImageMagickDistribution for sandboxed macOS app usage.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${PROJECT_ROOT}/Resources/ImageMagickDistribution"

# Check for Homebrew ImageMagick installation
if [ ! -d "/opt/homebrew/Cellar/imagemagick" ]; then
    echo "Error: Homebrew ImageMagick not found at /opt/homebrew/Cellar/imagemagick"
    exit 1
fi

IM_VERSION_DIR=$(find /opt/homebrew/Cellar/imagemagick -maxdepth 1 -mindepth 1 -type d | sort -V | tail -n 1)
echo "==> Using ImageMagick from ${IM_VERSION_DIR}"

# Prepare target directories
rm -rf "${TARGET_DIR}/bin" "${TARGET_DIR}/lib" "${TARGET_DIR}/etc" "${TARGET_DIR}/modules"
mkdir -p "${TARGET_DIR}/bin"
mkdir -p "${TARGET_DIR}/lib"
mkdir -p "${TARGET_DIR}/etc/ImageMagick-7"
mkdir -p "${TARGET_DIR}/modules/coders"

# 1. Copy magick executable
echo "==> Copying magick binary..."
cp "${IM_VERSION_DIR}/bin/magick" "${TARGET_DIR}/bin/magick"
chmod +x "${TARGET_DIR}/bin/magick"

# 2. Copy core dylibs
echo "==> Copying MagickCore and MagickWand dylibs..."
cp -P "${IM_VERSION_DIR}/lib"/libMagick*.dylib "${TARGET_DIR}/lib/"

# 3. Copy coder modules (*.so)
echo "==> Copying coder modules..."
if [ -d "${IM_VERSION_DIR}/lib/ImageMagick/modules-Q16HDRI/coders" ]; then
    cp "${IM_VERSION_DIR}/lib/ImageMagick/modules-Q16HDRI/coders"/*.so "${TARGET_DIR}/modules/coders/"
elif [ -d "${IM_VERSION_DIR}/lib/ImageMagick-7.1.2/modules-Q16HDRI/coders" ]; then
    cp "${IM_VERSION_DIR}/lib/ImageMagick-7.1.2/modules-Q16HDRI/coders"/*.so "${TARGET_DIR}/modules/coders/"
fi

# 4. Copy configuration XMLs
echo "==> Copying XML configuration files..."
if [ -d "${IM_VERSION_DIR}/etc/ImageMagick-7" ]; then
    cp "${IM_VERSION_DIR}/etc/ImageMagick-7"/*.xml "${TARGET_DIR}/etc/ImageMagick-7/"
fi

# 5. Ad-hoc codesign bundled binaries and dylibs for App Sandbox compliance
echo "==> Ad-hoc code signing bundled binaries..."
for dylib in "${TARGET_DIR}/lib"/*.dylib; do
    if [ -f "${dylib}" ] && [ ! -L "${dylib}" ]; then
        codesign --force --deep --sign - "${dylib}" 2>/dev/null || true
    fi
done

for mod in "${TARGET_DIR}/modules/coders"/*.so; do
    if [ -f "${mod}" ]; then
        codesign --force --deep --sign - "${mod}" 2>/dev/null || true
    fi
done

codesign --force --deep --sign - "${TARGET_DIR}/bin/magick" 2>/dev/null || true

echo "==> Bundling completed successfully at ${TARGET_DIR}"
