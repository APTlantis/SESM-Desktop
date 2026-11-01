# Architecture and interfaces

The Rust engine owns original bytes, XML analysis, metadata JSON, validation, templates, preview rasterization, revisions, approval, and copy export. The Tauri shell owns native selectors, application-data storage, in-memory document identifiers, and typed commands. React displays only text, form values, findings, and PNG data URLs.

## IPC

Commands: `open_documents`, `edit_metadata(id,draft)`, `approve_document(id,revision,acknowledge)`, `remove_document(id)`, `list_templates`, `save_template(id,name)`, `delete_template(name)`, `apply_template(id,name,overwrite)`, `preferences`, `save_preferences(preferences)`, `export_documents`, `cancel_export`.

`open_documents` prompts natively and returns document snapshots plus per-file errors. Import and export paths originate in Rust-native selectors. Metadata crosses IPC as JSON **strings**, preventing JavaScript numeric coercion. A snapshot includes ID, source hash, revision, draft, last valid metadata JSON, validation findings, observations, diff, approval, and optional raster preview. Edit/approval responses omit the unchanged image to avoid repeatedly transferring PNGs.

Raw JSON is an explicit draft. Frontend edits are held until validation; exports flush all pending drafts before collecting approved documents. Pending drafts cannot be approved. Engine edits invalidate approval and warning acknowledgement. Invalid drafts retain the last valid model but block approval/export.

`export_documents` creates a new timestamped folder under the selected parent. It snapshots approved revisions, blocks mutations during export, and emits `export-progress` after each file. Cancel sets an atomic flag checked between files and immediately before commit. Each file is staged, revalidated, synced, and committed without overwriting existing files. The receipt is updated after each result; partial success remains inspectable.

## Data formats

Templates: `{ "version": 1, "name": "...", "patch_json": "{...}" }`. Names are stored using SHA-256 filenames, so user text cannot escape the template directory. Patches recursively fill missing keys; arrays are atomic; `overwrite` contains explicitly selected JSON pointers. Saved templates omit standard file-identity paths, links, and integrity. Unknown extension fields remain author responsibility.

Preferences: version 1, `preview_background` (`checker`, `dark`, `light`), `editor_tab` (`fields`, `json`). Writes stage and rename files in application data.

Receipts: version 1, application version, destination, cancellation flag, per-file status, source/output SHA-256, warning acknowledgement, and full validation result. Paths are local operational records; receipts are not automatically embedded or published.

## Preservation and validation

Parse original UTF-8 using bounded XML events and namespace-aware XML analysis. Record exact metadata byte ranges. Replace that block or insert a block inside the root; never serialize the full XML tree. An empty root necessarily expands from a self-closing tag into an opening/closing pair. Serialize CDATA delimiters safely.

Duplicate JSON object keys are rejected before constructing the metadata model; they are never silently collapsed during editing. Numeric tokens are retained with arbitrary precision in Rust and lossless JSON handling in the frontend.

SESM schema validation uses the asset wrapper expected by the pinned canonical schema and an offline Draft 2020-12 validator. Compatible 0.2.0 blocks are retained. New blocks start with the sole required `sesm_version` field. Semantic fields are authored, never fabricated. Extracted properties remain observations until a user chooses them.

Schema validity and safe-profile review are independent. Findings have category, severity, code, message, and location. Forbidden content blocks export; warnings require acknowledgement and remain unverified. The renderer disables string resource resolution and nested SVG images, bounds embedded raster inputs and preview dimensions, and returns PNG only.

Export additionally compares original and edited raster output under the same renderer/fonts. A mismatch blocks that file, including CSS child-selector changes caused by adding a metadata node. A rendering error also blocks export because appearance cannot be checked. This is a supported-renderer comparison, not a guarantee for every native editor or browser.
