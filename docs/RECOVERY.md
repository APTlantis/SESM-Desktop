# Recovery and local data

Source SVGs are read-only inputs. If an export is interrupted, keep the destination and `sesm-export-receipt.json`. Completed SVGs are independent copies. Reopen them in the app to inspect their metadata and validation results. A process crash may leave `.sesm-*.partial` files; these are incomplete staging artifacts, not successful outputs. Compare receipt hashes before using completed copies. Choose a new destination for another export; do not delete prior receipts to force a retry.

Edits are in memory until exported. Closing after the discard prompt loses unexported drafts; reopening the original restores its original metadata. There is no unattended write-back or autosave to source folders.

Templates and preferences live under the platform application-data directory for `net.aptlantis.sesm-desktop` (typically `%APPDATA%` on Windows, `$XDG_DATA_HOME`/`~/.local/share` on Linux, and `~/Library/Application Support` on macOS). The Rust `app_data_dir` API determines the exact directory. Back up `templates/*.json` and `preferences.json` before resetting app data. Templates are versioned JSON and never contain executable code.

To reset corrupt preferences, close the app and rename `preferences.json` to a backup. To recover a corrupt template, preserve it outside `templates` and repair its JSON/version before restoring it. The app reports corrupt template files rather than silently discarding them. Do not delete exported SVGs or original assets during application-data recovery.

Build caches (`node_modules`, `target`, `dist`, `.work`) can be regenerated from lockfiles. Original pipeline and Atlas inputs are not build dependencies. Verify bundled source hashes with `npm run verify:sources`.
