# SESM Desktop

An offline SVG metadata editor for Windows, Linux, and macOS. Version **0.1.0**, theme: **Portable, self-describing SVG assets**. Application chrome uses the existing **Aptlantis-Factor** dark palette.

Open SVGs, inspect a raster preview and observed properties, edit structured fields or lossless JSON, validate, approve each file, and export copies into a new folder. Reusable templates fill missing values and expose conflicts for explicit replacement. No account, upload, Python installation, or Aptlantis pipeline is required by the installed app.

## Develop

Install Node.js, Rust stable with the platform C++/desktop build prerequisites, and Tauri 2 prerequisites. On Windows use the MSVC Rust toolchain and WebView2 runtime; Linux needs WebKitGTK 4.1 and the Tauri development libraries; macOS needs Xcode command-line tools.

```text
npm ci
npm run tauri dev
```

```text
npm run verify:sources
npm test
cargo test -p sesm-engine --locked
npm run build
cargo check -p sesm-desktop --locked
```

Use `npm run test:ui` for browser frontend tests (install Playwright Chromium first). `npm run dev` alone is an interface preview: local file access requires the desktop application.

## Use

1. Select **Open SVGs** and choose one SVG or a batch.
2. Inspect the preview, observations, source identity, and findings. Preview rendering never executes SVG markup in the app webview.
3. Edit fields or raw JSON. Choose **Validate draft** to refresh results and the diff. Raw invalid JSON stays visible while the last valid model is retained.
4. Apply a saved template to fill missing values. Select individual conflict paths to replace existing values, then apply selected replacements.
5. Review findings and proposed changes. Acknowledge warnings where present, then approve each file.
6. Choose **Export approved copies**, select a parent folder, and inspect the result. The app creates a new `SESM-Export-<timestamp>` child containing SVG copies and `sesm-export-receipt.json`.

Edits invalidate approval. Export never overwrites source files or an existing destination. Files changed outside the app after import fail export until reopened and reviewed. Cancellation retains completed copies and removes incomplete staged files.

Export compares original and edited raster output and rejects files whose appearance changes or cannot be verified within the renderer limits. This catches structural CSS selectors affected by inserting a metadata element.

## Supported documents

UTF-8 SVG (BOM supported), maximum 5 MiB, XML depth 128, SESM JSON 64 KiB, preview canvas 16 megapixels. New blocks use SESM 0.3.0; compatible 0.2.0 blocks retain their version. Unknown metadata and arbitrary-precision numeric values survive editing. DTDs, external entities, executable SVG content, and ambiguous duplicate SESM blocks block export. Unsupported versions and encodings are reported without rewriting their source files.

External image references are never loaded. Bounded embedded PNG/JPEG/GIF/WebP images can be previewed; other embedded image types are unsupported. Renderer support differs from browsers for animation, interactive content, fonts, and unsupported SVG features. Raster previews are inspection aids, not guarantees of native editor rendering.

Validation distinguishes XML, schema, safe-profile, privacy, and integrity findings. A schema-valid SVG with warnings remains `sesm-unverified`; acknowledgement does not make it safe. Integrity claims are preserved without verification. Output hashes belong to the external receipt, avoiding a self-referential embedded whole-file hash.

## Project records

- [Architecture and interfaces](docs/ARCHITECTURE.md)
- [Trust boundary](docs/TRUST.md)
- [Recovery and local data](docs/RECOVERY.md)
- [Release and packaging](docs/PACKAGING.md)
- [v0.1.0 release evidence](docs/releases/0.1.0.md)

Development source intake is explicit (`scripts/intake-sources.py`); ordinary builds and installed workflows use only local runtime resources. Original schemas, artwork, and historical pipeline runs are not modified. Source hashes are recorded in `resources/source-receipts.json`.
