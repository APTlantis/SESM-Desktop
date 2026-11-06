# SESM Desktop v0.1.0 — Test Scripts

**Version:** 1.0  
**Date:** 2026-11-06  
**Purpose:** Automation scripts for acceptance testing and evidence collection

---

## Script Overview

This directory contains scripts to automate various aspects of SESM Desktop v0.1.0 acceptance testing for DRS Phase 4 release readiness.

### Scripts Directory Structure

```
scripts/
├── README.md                    # This file
├── collect-dependencies.sh     # Collect dependency versions for evidence
├── run-acceptance-tests.sh     # Main test execution script
├── verify-evidence.sh          # Verify integrity of collected evidence
├── verify-preservation.sh      # Verify byte preservation (from EVIDENCE-COLLECTION.md)
└── acceptance/                 # Additional acceptance test scripts (future)
```

---

## Script Descriptions

### 1. `collect-dependencies.sh`

**Purpose:** Collects all dependency versions for evidence collection

**Features:**
- Platform detection (Linux, macOS, Windows/WSL)
- Collects Node.js, npm, Rust, Cargo, Git versions
- Collects platform-specific dependencies (libwebkit2gtk, Homebrew, etc.)
- Collects system information (OS, CPU, memory, disk)
- Outputs structured JSON for evidence

**Usage:**
```bash
# Run from project root
./scripts/collect-dependencies.sh

# Output will be saved to: evidence/local/{platform}/dependencies.json
```

**Example Output:**
```json
{
  "platform": "linux",
  "collected_at": "2026-11-06T14:30:22Z",
  "dependencies": {
    "nodejs": {
      "version": "v20.12.2",
      "command": "node --version"
    },
    "npm": {
      "version": "10.8.1",
      "command": "npm --version"
    },
    "rustc": {
      "version": "rustc 1.75.0",
      "command": "rustc --version"
    }
  },
  "system_info": {
    "os_name": "Ubuntu",
    "os_version": "22.04.4",
    "kernel_version": "5.15.0-91-generic"
  }
}
```

---

### 2. `run-acceptance-tests.sh`

**Purpose:** Main script for running acceptance tests

**Features:**
- Comprehensive test catalog (88 tests across 7 categories)
- Test categorization (functional, safety, preservation, visual, recovery, regression, cross-platform)
- Critical test identification
- Platform-specific test handling
- Evidence collection and organization
- Test result recording
- Summary reporting

**Usage:**
```bash
# Show help
./scripts/run-acceptance-tests.sh --help

# List all tests
./scripts/run-acceptance-tests.sh --list

# Run all tests
./scripts/run-acceptance-tests.sh --all

# Run tests by category
./scripts/run-acceptance-tests.sh --category functional
./scripts/run-acceptance-tests.sh --category safety
./scripts/run-acceptance-tests.sh --category preservation
./scripts/run-acceptance-tests.sh --category critical

# Run specific test
./scripts/run-acceptance-tests.sh --test FT-01
./scripts/run-acceptance-tests.sh --test ST-05

# Dry run (show what would be executed)
./scripts/run-acceptance-tests.sh --category functional --dry-run

# Verbose output
./scripts/run-acceptance-tests.sh --category preservation --verbose
```

**Test Categories:**

| Category | Tests | Count | Critical |
|----------|-------|-------|----------|
| functional | FT-01 to FT-40 | 40 | 23 |
| safety | ST-01 to ST-10 | 10 | 10 |
| preservation | PT-01 to PT-07 | 7 | 7 |
| visual | VT-01 to VT-04 | 4 | 2 |
| recovery | RT-01 to RT-09 | 9 | 3 |
| regression | RG-01 to RG-08 | 8 | 8 |
| cross-platform | CP-01 to CP-04 | 4 | 4 |
| **Total** | | **88** | **61** |

**Note:** The `--category critical` option runs only the 61 critical tests required for DRS acceptance.

---

### 3. `verify-evidence.sh`

**Purpose:** Verifies the integrity of all collected evidence

**Features:**
- Hash file verification (SHA-256)
- JSON file validation
- PNG file format verification
- Log file verification
- Receipt file validation
- Metadata file validation
- Comprehensive summary reporting

**Usage:**
```bash
# Run from project root
./scripts/verify-evidence.sh

# This will verify all evidence in:
# - evidence/local/linux/
# - evidence/local/macos/
# - evidence/local/windows/
# - evidence/
```

**Output:**
```
==========================================================
  SESM Desktop v0.1.0 - Evidence Verification
==========================================================

[INFO] Verifying evidence for platform: linux

[INFO] Verifying hash files in: evidence/local/linux
  ✓ evidence/local/linux/package.sha256
  ✓ evidence/local/linux/hashes/source.svg.sha256

[INFO] Verifying JSON files in: evidence/local/linux
  ✓ evidence/local/linux/dependencies.json
  ✓ evidence/local/linux/workflows/ft-01/metadata.json

... (more output) ...

==========================================================
  Evidence Verification Summary
==========================================================

  Total Files Checked:   42
  Valid Files:           42
  Invalid Files:         0
  Warnings:              0

[SUCCESS] All evidence validated successfully!
```

**Exit Codes:**
- `0` - All evidence validated successfully
- `1` - One or more files failed validation

---

### 4. `verify-preservation.sh`

**Purpose:** Verifies byte preservation outside SESM metadata blocks

**Features:**
- Compares source file bytes outside SESM block before and after editing
- Verifies source file is unchanged after export
- Handles both files with and without existing SESM blocks
- CDATA-aware comparison

**Usage:**
```bash
# Verify preservation between source and output
./scripts/verify-preservation.sh <source-file> <output-file>

# Example
./scripts/verify-preservation.sh tests/fixtures/atlas-infographic.svg "SESM-Export-*/atlas-infographic.svg"
```

**Output:**
- `PRESERVATION VERIFIED: Bytes outside SESM block are unchanged` (Exit code: 0)
- `PRESERVATION FAILED: Bytes outside SESM block have changed` (Exit code: 1)

---

## Test Automation Strategy

### Current State

The scripts provide a **framework** for test automation. Currently:

- ✅ **Environment collection** - Fully automated
- ✅ **Hash verification** - Fully automated
- ✅ **File format validation** - Fully automated
- ⚠️ **Test execution** - Framework in place, but many tests require desktop application
- ⚠️ **Preservation verification** - Framework in place, requires integration

### What's Automated

1. **Dependency collection** - `collect-dependencies.sh`
2. **Evidence verification** - `verify-evidence.sh`
3. **Test catalog** - `run-acceptance-tests.sh` (lists tests, records results)
4. **Test file generation** - `run-acceptance-tests.sh` (creates test SVGs for safety/regression tests)

### What Requires Manual Execution

The following tests require the desktop application to be running and currently cannot be fully automated:

1. **Import tests** (FT-01 to FT-10) - Require file picker interaction
2. **Editing tests** (FT-11 to FT-20) - Require form interaction
3. **Template tests** (FT-26 to FT-30) - Require UI interaction
4. **Approval/Export tests** (FT-31 to FT-40) - Require UI interaction
5. **Visual tests** (VT-01 to VT-04) - Require raster comparison
6. **Recovery tests** (RT-01 to RT-09) - Require application crash/cancellation
7. **Cross-platform tests** (CP-01 to CP-04) - Require results from multiple platforms

### Future Automation

To achieve full automation, consider:

1. **Tauri IPC Automation**
   - Use Tauri's `@tauri-apps/api` to send commands programmatically
   - Example: `invoke('open_documents')`, `invoke('edit_metadata', {id, draft})`
   - See `src/api.ts` for available commands

2. **Test Fixture Automation**
   - Generate test SVGs programmatically
   - Use existing test fixtures from `tests/fixtures/`

3. **Headless Testing**
   - Use Tauri's headless mode for automated testing
   - Consider Playwright or similar for UI automation

4. **Cross-Platform Automation**
   - Run tests in CI/CD pipelines
   - Use VMs or containers for each platform
   - Compare results across platforms

---

## Evidence Collection Workflow

### Before Testing

```bash
# 1. Set up VM (see TESTING-VM-GUIDE.md)
# 2. Install dependencies
# 3. Build the application
npm run build
npm run tauri build

# 4. Collect environment evidence
./scripts/collect-dependencies.sh

# 5. Take snapshot (VM-specific)
```

### During Testing

```bash
# 1. Execute tests manually or via scripts
./scripts/run-acceptance-tests.sh --category functional --dry-run
# Then execute tests manually following TEST-PLAN.md

# 2. Capture screenshots for each test
# 3. Save export receipts
# 4. Calculate hashes
sha256sum source.svg > evidence/local/linux/hashes/source.svg.sha256
```

### After Testing

```bash
# 1. Verify all evidence
./scripts/verify-evidence.sh

# 2. Create evidence archive (see EVIDENCE-COLLECTION.md)
# 3. Commit evidence to repository
git add evidence/
git commit -m "Evidence: Linux acceptance test results"
```

---

## Platform-Specific Notes

### Linux

- Ensure `sha256sum`, `jq`, and `file` commands are installed
- Install dependencies via `sudo apt install -y sha256sum jq file`
- Use AppImage or DEB package for testing

### macOS

- Ensure `shasum`, `jq`, and `file` commands are installed
- Install via Homebrew: `brew install jq`
- Use DMG package for testing
- May need to right-click to open unsigned application

### Windows

- Ensure PowerShell is available
- Use `Get-FileHash -Algorithm SHA256` for hash verification
- Use MSIX package for testing
- Scripts may need adjustment for Windows paths

---

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: SESM Desktop Acceptance Tests

on:
  push:
    branches: [ main, Cobra ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    name: Acceptance Tests
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run frontend tests
      run: npm test
    
    - name: Set up Rust
      uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
    
    - name: Run engine tests
      run: cargo test -p sesm-engine --locked
    
    - name: Build application
      run: npm run build
    
    - name: Collect environment evidence
      run: ./scripts/collect-dependencies.sh
    
    - name: Verify evidence
      run: ./scripts/verify-evidence.sh
    
    - name: Upload evidence
      uses: actions/upload-artifact@v4
      with:
        name: acceptance-evidence
        path: evidence/
```

### Manual Testing with VMs

For cross-platform testing, use VMs as described in `TESTING-VM-GUIDE.md`:

```bash
# On Linux VM
./scripts/run-acceptance-tests.sh --category critical
./scripts/verify-evidence.sh

# On macOS VM
./scripts/run-acceptance-tests.sh --category critical
./scripts/verify-evidence.sh

# On Windows (Git Bash or WSL)
./scripts/run-acceptance-tests.sh --category critical
./scripts/verify-evidence.sh
```

---

## Troubleshooting

### Script Permissions

If scripts fail with "Permission denied":

```bash
chmod +x scripts/*.sh
```

### Missing Dependencies

If scripts fail with "command not found":

```bash
# Linux (Ubuntu/Debian)
sudo apt install -y jq file

# macOS
brew install jq

# Windows (via Chocolatey)
choco install jq
```

### Hash Verification Failures

If hash verification fails:
- Ensure the referenced file exists
- Check that the file hasn't been modified
- Verify the hash file format (SHA-256 hash followed by two spaces, then filename)

### JSON Validation Failures

If JSON validation fails:
- Check for syntax errors in JSON files
- Ensure proper escaping of special characters
- Use `jq` to validate manually: `jq empty file.json`

---

## Related Documents

- `docs/TEST-PLAN.md` - Comprehensive test definitions
- `docs/TESTING-VM-GUIDE.md` - VM setup guide
- `docs/EVIDENCE-COLLECTION.md` - Evidence collection procedures
- `docs/LINUX-ACCEPTANCE.md` - Linux acceptance report template
- `docs/MACOS-ACCEPTANCE.md` - macOS acceptance report template
- `docs/Validation-Checklist.md` - Release checklist

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-11-06 | Initial version with core scripts |

---

**Document Status:** Ready for use  
**Last Updated:** 2026-11-06  
**Owner:** SESM Desktop Team
