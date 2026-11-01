# Packaging

Version 0.1.0 is an implementation candidate. Public publication and paid signing are separate operations. Use the lockfiles. Package only after running tests and building the frontend.

- Windows: `npm run tauri build -- --no-bundle` creates the desktop executable. `scripts/package-windows.ps1` stages it with documentation, generates package assets, builds a development MSIX with the Windows SDK, and records hashes. Supply `-CertificatePath .\devcert.pfx` or an existing current-user `-CertificateThumbprint` to sign. The publisher is derived from the certificate subject; an explicitly supplied conflicting publisher is rejected before packaging. Unsigned packages are staging artifacts and cannot establish installation acceptance. Public release uses the portfolio's Microsoft Store identity and signing workflow.
- Linux: on a Linux runner with Tauri prerequisites, `npm run tauri build -- --bundles appimage`. Record the AppImage hash and test its actual installation/launch and workflows.
- macOS: on a macOS runner with Xcode prerequisites, `npm run tauri build -- --bundles app,dmg`. Record the app/DMG identity and hashes; signing/notarization and installation acceptance need platform-specific evidence.

Use `scripts/hash-artifacts.mjs <artifact> [...]` to produce a dated local hash record. Local records belong in `evidence/local`, and the final artifact hash must also be bound into release records before readiness is claimed. CI jobs build/test target-native packages but do not replace manual or automated native acceptance evidence.

After packaging, run `node scripts/record-evidence.mjs` to bind the current MSIX hash into the project-local candidate manifest/stage record and `evidence/artifacts.json`. This external packet avoids embedding the installer's own final hash into itself. A running executable may lock the usual build output on Windows; use an isolated `CARGO_TARGET_DIR=target/candidate` and pass `-Executable 'target\candidate\release\sesm-desktop.exe' -SkipBuild` to the Windows packaging script when preserving a running preview.

## Development certificate workflow

Generating a certificate does not sign an existing MSIX or install certificate trust. `winapp cert generate` uses `CN=Administrator` when it cannot find a manifest; the development package's publisher must match that subject exactly. Keep the generated PFX private; PFX/P12 files are ignored by source control.

```powershell
.\scripts\package-windows.ps1 -SkipBuild -Executable 'target\candidate\release\sesm-desktop.exe' -CertificatePath .\devcert.pfx
node scripts/record-evidence.mjs
```

The PFX is loaded ephemerally, without importing its key or changing trust stores. The default password matches the documented `winapp cert generate` development default. For a custom password, pass `-CertificatePassword (Read-Host -AsSecureString)`.

After successful signing, `evidence/local/signing.json` records the signer and `evidence/local/SESM-Desktop-development.cer` contains only the public certificate. To trust that certificate for local testing, run this explicitly in an **Administrator** PowerShell window from the project root:

```powershell
winapp cert install .\evidence\local\SESM-Desktop-development.cer
```

Then open the newly signed MSIX named in `evidence/artifacts.json`, rather than the earlier unsigned file. Certificate trust and successful installation remain separate acceptance steps. The packaging script never changes trust stores. Error `0x800B010A` indicates that Windows cannot build a trusted certificate chain; generating a PFX alone does not resolve it.

## Required acceptance on each platform

Install the exact packaged artifact. Launch without network access. Open the bundled representative SVGs, edit fields and JSON, test invalid JSON retention, save/reapply a template with a conflict, review and approve a batch, export copies, cancel a later export, reopen completed outputs, and verify hashes and untouched originals. Confirm keyboard navigation and close/remove discard prompts. Record OS, runtime version, artifact SHA-256, steps, results, and failures in a dated platform report.
