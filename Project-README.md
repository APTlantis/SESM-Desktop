# SESM Desktop project recovery map

Version: 0.1.0. Status: implementation candidate; release acceptance is evidence-gated.

Start with [README.md](README.md), then [architecture](docs/ARCHITECTURE.md), [recovery](docs/RECOVERY.md), and [release evidence](docs/releases/0.1.0.md). The approved proposal and scope documents remain the intent records.

The Rust workspace separates `crates/sesm-engine` from `src-tauri`. The React frontend is in `src`. `resources/source-receipts.json` records the schema, Factor theme, and fixture sources. `tests/fixtures` contains reviewed local copies, not live dependencies on external drives.

Build output is disposable (`target`, `dist`, `node_modules`). Templates and preferences belong to platform app data; exported SVGs and receipts belong to the selected destination. See recovery instructions before deleting application data.
