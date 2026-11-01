# SESM-Desktop agent instructions

Inherit `D:/AGENTS.md` and `D:/DRS/AGENTS.md`. Read `Project-README.md`, `SESM-Desktop.manifest.toml`, and `docs/ARCHITECTURE.md` before changes.

Preserve source SVG bytes outside the SESM insertion/replacement. Keep Rust file access behind native selectors; IPC accepts document identifiers, not arbitrary source paths. Never put imported SVG markup into the webview. Keep unknown metadata and arbitrary precision through both Rust and TypeScript paths. Revalidate outputs and require current per-file approval with explicit warning acknowledgement.

Use Aptlantis-Factor from recorded palette/token sources. Do not regenerate artwork, modify sibling projects, or add pipeline runtime dependencies. Runtime schema resources are pinned data, not a second governance suite.

Run engine tests, frontend tests/build, source receipt verification, and desktop compilation after related changes. Record actual platform evidence separately from builds. Keep release notes, recovery guidance, manifest, and validation checklist aligned; never infer installation or publication from a successful build.
