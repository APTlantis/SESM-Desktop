# Validation record

Date: 2026-10-31 (America/New_York). Status: implementation candidate; cross-platform release acceptance remains pending.

## Passed checks

- Rust engine: **18 integration tests passed**, including malformed/hostile XML, version/schema paths, unknown fields, arbitrary precision, duplicate JSON keys, CDATA/BOM/line endings, templates, source protection, collisions, changed sources, partial failures, cancellation, and reopening exports.
- Visual fixtures: unchanged raster output after metadata edits for real Atlas infographic, pipeline bars/artwork, exact Factor palette-board fixture, and embedded PNG fixture. The generated fixtures are identified as such in the source receipt.
- Export additionally checks original/edited raster equality. A regression test proves that CSS `:first-child` changes caused by metadata insertion are blocked before committing a copy. Unsupported renderer features still need native target review.
- Raster isolation: local and network references produce no loaded image; nested SVG payloads are rejected; malformed embedded rasters return explicit preview errors; actual embedded PNG pixels are verified.
- Frontend: **4 unit tests passed**, including arbitrary-precision form/JSON round trips and invalid drafts. **4 browser contract checks passed**, covering empty state, keyboard entry, approval invalidation, raw JSON errors, templates/conflicts, export receipts, modal keyboard focus, and Factor foreground contrast (at least 4.5:1 for tested text pairs).
- Frontend TypeScript/production build passed. Rust desktop compilation and strict Clippy passed. Source receipt verification passed for **9** bundled schema/theme/fixture records.
- Windows candidate build and development MSIX creation use the local MSVC Rust toolchain and Windows SDK MakeAppx. Exact final artifact identities are recorded in `evidence/artifacts.json` and the project manifest.

## Native observations and limits

An earlier Windows candidate launched with the exact title **SESM Desktop · Aptlantis-Factor** and displayed the Factor editor. Its native SVG file picker opened successfully. Subsequent UI automation was interrupted by live window input (`user input was detected in this window`) and geometry recovery failed (`coordinate input geometry is unavailable`); no full native edit/template/export cycle is claimed. The final candidate includes subsequent raster diagnostics, modal keyboard handling, and visual-preservation checks and requires its own full native acceptance.

Browser workflow tests mock native IPC; they verify frontend behavior, not the Rust engine/dialog integration. Rust tests independently exercise the real engine and filesystem.

The restricted Windows sandbox produced unrelated realpath `EPERM`, temporary-directory/rename `Access Denied`, and rustfmt errors. The same affected checks passed outside that sandbox. Vite now excludes Rust build output from watching after a concurrent test executable produced `EBUSY`. A running earlier executable prevented replacement, so the final Windows build uses an isolated `target/candidate` directory.

## Open release gates

- Development MSIX is now **self-signed** with the user's existing `CN=Administrator` certificate. Windows Authenticode returned **Valid**; the embedded CMS signature was also checked cryptographically and its signer matched the manifest publisher. Packaging did not change certificate trust stores. Actual package installation, launch, core workflows, recovery, uninstall/data preservation, and exact-artifact runtime evidence remain pending.
- Linux AppImage and macOS app/DMG build jobs are provided but were not run on this Windows host. No native artifacts or acceptance are claimed for those platforms.
- No cloud publication, Store submission, paid signing, or dependency/fixture public-distribution review was performed.
- Parent DRS/index registration changes are documented in `docs/PARENT-REGISTRATION.md`; parent files were left untouched as requested.

The original unsigned candidate failed local installation with certificate-chain error `0x800B010A`. Inspection confirmed it had no signature, and the generated PFX subject (`CN=Administrator`) differed from the package's previous publisher (`CN=Aptlantis Development`). The packaging script now accepts PFX files, derives the publisher from the certificate, rejects explicit publisher mismatches, signs the new package, and records public signing evidence in `evidence/signing.json`. The original PFX is unchanged and ignored by source control.

The canonical DRS integrity helper verifies the current declared artifact hash (`evidence/integrity-check.json`). The release gate rejects readiness with exactly two pending stages: `install-upgrade` and `runtime` (`evidence/drs-release-gate.json`). First-release migration is not applicable; templates/preferences start at storage version 1.
