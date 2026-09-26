# Magiq

<p align="center">
  <strong>The raw, uncompromised power of ImageMagick — reimagined as a premium, native macOS application.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-15%2B%20%7C%20Apple%20Silicon-blue?style=flat-square&logo=apple" alt="macOS 15+ Apple Silicon" />
  <img src="https://img.shields.io/badge/Swift-6.0%20%7C%20SwiftUI-orange?style=flat-square&logo=swift" alt="Swift 6.0 SwiftUI" />
  <img src="https://img.shields.io/badge/Engine-ImageMagick%207%20HDRI-purple?style=flat-square" alt="ImageMagick 7 HDRI" />
  <img src="https://img.shields.io/badge/Telemetry-Zero%20%2F%20100%25%20Offline-success?style=flat-square" alt="Zero Telemetry" />
  <img src="https://img.shields.io/badge/Sandbox-App%20Sandbox%20Enforced-green?style=flat-square" alt="App Sandbox" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="MIT License" />
</p>

---

## Why Magiq?

For over three decades, **ImageMagick** has stood as the gold standard of digital image manipulation. It powers the web's largest media pipelines, converts obscure legacy formats effortlessly, and handles color spaces with mathematical rigor. 

Yet, for creative professionals, photographers, and developers, working with it every day meant wrestling with cryptic terminal flags, memorizing syntax like `-level 10%,90%,1.2`, and enduring the frustration of editing blindly without visual feedback.

**Magiq** transforms this experience. Built from the ground up exclusively for macOS and Apple Silicon, Magiq wraps the complete ImageMagick 7 feature set in an elegant, HIG-compliant interface that feels right at home on your Mac:

- **100% Offline & Private:** No network calls, no analytics, no telemetry, no crash report uploads. Your photos and graphics never leave your hardware.
- **Hybrid Performance Engine:** Direct C-level interop via `libMagickWand` for low-latency live preview rendering, paired with a full bundled `magick` CLI distribution for exhaustive format delegate parity.
- **Hardware-Aware Memory Discipline:** Bounded concurrency worker pools, deterministic RAII memory disposal, and zero memory leaks.
- **Crafted for Speed:** Real-time 45ms debounced previews, custom keyboard shortcuts, live histogram analysis, and folder-watching automated batch queues.

---

## Key Features

### 🎨 Color, Tone & Film Emulation
- **Professional Color Space Management:** Instant conversion between `sRGB`, `CMYK` (print-ready preflight), `Display P3` (wide gamut), `Grayscale`, and `CIELAB`.
- **Bit Depth Selection:** Seamlessly switch between 8-bit standard output and 16-bit HDR / RAW high dynamic range fidelity.
- **Palette Quantization:** Intelligent color palette reduction (256, 128, 64, 32, 16 colors) using Floyd-Steinberg dithering for featherweight PNG and retro GIF graphics.
- **Levels & Gamma Scopes:** Precision adjustments for Black Point, Gamma Point, and White Point directly linked to live histogram scopes.
- **Film Look Profiles:** Handcrafted color recipes simulating analog film stocks (Kodak Portra, Fuji Velvia, Ilford Tri-X Noir, and Vintage 70s).
- **Core Tonal Tools:** Non-destructive Brightness, Contrast, Saturation, Sepia tone, and Color Inversion (Negate).

### 📐 Geometry & Framing
- **Smart Resizing:** Freeform or aspect-ratio locked pixel resizing with instant presets (25%, 50%, 75%, 100%).
- **Interactive Cropping:** Drag-handle overlay with rule-of-thirds grid and standard aspect presets (`1:1`, `4:5`, `16:9`, `3:2`, `Free`).
- **Rotation & Orientation:** Free angle rotation (0–360°), 90-degree steps, and lossless Horizontal / Vertical flips.
- **Auto-Trim:** Automatically trim uniform background margins with adjustable fuzz tolerance percentage.
- **Borders & 3D Frames:** Solid colored outer borders and classical beveled matte frames with adjustable depth, bevel offsets, and curated palette choices.

### 🎭 Stylize & Creative Filters
- **Artistic Painting & Drawing:** Turn photographs into oil paintings (`-paint`), charcoal illustrations (`-charcoal`), and pencil sketches (`-sketch`).
- **Emboss & Edge Detection:** Extract structural relief contours and high-contrast outlines (`-emboss`, `-edge`).
- **Film Noise Simulation:** Inject organic synthetic film grain using Gaussian, Uniform, Poisson, Impulse, or Laplacian distributions.
- **Focal Clarity:** High-precision Gaussian Blur and Unsharp Mask sharpening.
- **Noise Suppression:** Wavelet denoise and despeckle filters to clean low-light sensor grain.

### 🔍 Analysis, Inspection & Export
- **Real-Time 256-Bin Histogram:** Live RGB and luminance channel graphs with instantaneous shadow and highlight clipping indicators.
- **Interactive Pixel Loupe:** Circular magnifying glass with crosshairs, subpixel coordinates, and precise hex/RGB values.
- **Visual Image Compare & Diff:** Compare two images side-by-side or calculate pixel-level difference masks and numerical distortion scores.
- **Horizontal & Vertical Append:** Merge and stitch multiple images side-by-side or in vertical collage strips.
- **Target File Size Optimizer ("Export Sizer"):** Specify a target file budget (e.g. max 500 KB), and Magiq automatically calculates the ideal compression curve.
- **Typography Watermarks:** Text annotations with 9-point gravity anchoring, font scaling, and custom opacity.
- **Metadata HUD & Privacy Stripping:** Read and audit EXIF, IPTC, and XMP camera metadata, with one-click GPS coordinate stripping.
- **Multi-Page Document Support:** Navigate, preview, and extract individual pages from multi-page PDFs and TIFF containers.

### ⚡ Batch Automation & macOS Integration
- **Batch Processing Queue:** Convert hundreds of mixed-format images simultaneously with bounded worker pool concurrency to keep RAM usage lean and steady.
- **Automated Folder Watcher:** Monitor target directories and automatically apply presets to incoming images as they arrive.
- **Customizable Keyboard Shortcuts:** Full user-definable keyboard shortcuts with dedicated preferences and instant default restore.
- **Quick Look Extension:** Instant previewing of ImageMagick-exclusive formats right in macOS Finder.
- **Headless CLI Mode:** Integrate Magiq into macOS Shortcuts and Finder Quick Actions via `--convert`.

---

## Format Support

Powered by ImageMagick 7, Magiq opens and exports across industry-standard and specialized media formats:

| Category | Supported Formats |
| :--- | :--- |
| **Modern Web** | WebP, AVIF, JPEG XL, PNG, JPEG, SVG |
| **Photography & RAW** | HEIC, Apple ProRAW, DNG, CR2, NEF, ARW, TIFF |
| **Graphics & Production** | PSD, PDF, EPS, BMP, TGA, ICO, GIF, JP2, HDR, EXR |

---

## Architecture & Technical Design

Magiq uses a deliberate **hybrid architecture** engineered specifically for the constraints of macOS and Apple Silicon:

```
┌───────────────────────────────────────────────────────────┐
│                     Magiq UI (SwiftUI)                    │
│   • Inspector Panels   • Interactive Canvas   • Presets   │
└──────────────┬────────────────────────────┬───────────────┘
               │                            │
      [ Hot / Interactive ]        [ Deep / Batch Parity ]
               │                            │
               ▼                            ▼
  ┌─────────────────────────┐  ┌─────────────────────────┐
  │   libMagickWand (C API) │  │    magick CLI Process   │
  │ • Real-time live render │  │ • Obscure delegates    │
  │ • 45ms debounced preview│  │ • Complex script ops    │
  │ • Deterministic RAII    │  │ • Isolated subprocesses │
  └─────────────────────────┘  └─────────────────────────┘
```

1. **Hot Path (`libMagickWand` / C API):**
   Live inspector tweaks, interactive canvas zoom, histogram generation, and Loupe sampling invoke bundled C dynamic libraries directly. There is zero subprocess spawn overhead, keeping memory and CPU utilization near native speeds.
2. **Deterministic RAII Memory Discipline:**
   Every `MagickWand`, `PixelWand`, and `DrawingWand` pointer is safely encapsulated within Swift classes with dedicated `deinit` hooks calling `DestroyMagickWand` and `MagickRelinquishMemory`.
3. **Safe Subprocess Path (`magick` CLI):**
   Heavy batch jobs and obscure image delegate operations execute via argument arrays—never shell strings—guaranteeing security and App Sandbox compliance.

---

## Privacy & Security

Your trust is paramount. Magiq is crafted to be a beacon of user privacy:

- **App Sandbox Active:** Magiq runs strictly within macOS App Sandbox restrictions.
- **Security-Scoped Bookmarks:** File system access is granted strictly through explicit user interaction (Open panels, drag-and-drop, or selected watch folders).
- **Zero Network Activity:** No network connections are initiated. No telemetry, no usage metrics, no third-party tracking libraries, and no hidden update pings.
- **One-Click Privacy Reset:** Instantly revoke all security-scoped file permissions and purge cached states from Settings.

For full details, review [PRIVACY.md](./PRIVACY.md).

---

## Getting Started

### System Requirements
- **Operating System:** macOS 15.0 (Sequoia) or later
- **Architecture:** Apple Silicon (M1/M2/M3/M4 and variants)
- **Xcode:** 16.0+ (for building from source)

### Building from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/bezelye404/Magiq.git
   cd Magiq
   ```

2. **Ensure dependencies are installed (Homebrew):**
   ```bash
   brew install imagemagick swiftlint swiftformat
   ```

3. **Open and run in Xcode:**
   ```bash
   open Magiq.xcodeproj
   ```
   Select the `Magiq` scheme and choose **Product > Run** (`Cmd + R`).

4. **Run the Test Suite:**
   ```bash
   xcodebuild -scheme Magiq -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO
   ```

---

## Documentation

- [PRIVACY.md](./PRIVACY.md) — Comprehensive privacy commitments and data handling policies.
- [ARCHITECTURE.md](./ARCHITECTURE.md) — Deep dive into the hybrid C/CLI engine design.
- [CONTRIBUTING.md](./CONTRIBUTING.md) — Guidelines for code style, branching, and pull requests.
- [ROADMAP.md](./ROADMAP.md) — Current development phases and upcoming milestones.

---

## License

Magiq is released under the [MIT License](./LICENSE). 

*Note: Bundled ImageMagick components and delegate libraries retain their respective upstream licenses. See their respective notices for details.*
