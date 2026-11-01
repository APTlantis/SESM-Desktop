# Risk Assessment

| Risk | Consequence | Proposed control |
|---|---|---|
| SVG active content or external references | Unsafe preview | Restrict/sandbox preview; test hostile SVG fixtures |
| XML round-trip rewriting | Visual changes or data loss | Preserve non-SESM content; fixture-based comparisons and regression tests |
| Existing unknown SESM fields | Metadata loss | Lossless preservation and explicit merge rules |
| Template application in batches | Accidental overwrites | Per-file diff/review and non-destructive export defaults |
| Self-referential integrity hashes | Invalid hashes after embedding | Specify hash target/scope; avoid naïve whole-file embedded hash |
| Cross-platform Tauri/webview differences | One OS fails release | Test actual builds and workflows on all three platforms |
| SESM specification evolution | Version mismatch | Explicit supported versions; warn on unsupported versions |
| Sensitive data in metadata | Public disclosure | Warnings for secret-like values and private paths |
| Scope expansion into theme tooling | Delayed v0.1 | Keep optional integrations out of completion criteria |

Implementation ownership: the Rust engine owns XML preservation, extraction, schema/safety checks and staged export; the desktop shell owns selectors and local data; the frontend owns draft/review presentation and approval controls. Regression coverage lives in `crates/sesm-engine/tests/workflows.rs`, `src/model.test.ts`, and `tests/browser/workflows.spec.ts`. Platform release owners must complete the native procedures in `docs/PACKAGING.md`; build success does not close those risks.
