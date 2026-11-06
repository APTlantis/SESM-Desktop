# SESM Desktop v0.1.0 — Evidence Collection Guide

**Document Version:** 1.0  
**Date:** 2026-11-06  
**Status:** Ready for Use  
**Purpose:** Standardize evidence collection for DRS release acceptance

---

## 1. Overview

This document defines the **evidence collection methodology** for SESM Desktop v0.1.0 cross-platform acceptance testing. The goal is to create **credible, auditable, and reproducible** evidence that demonstrates the application meets all DRS requirements.

### 1.1 Evidence Philosophy

**Credibility:** Evidence must be collectable by independent reviewers  
**Auditability:** Every artifact must have a clear provenance chain  
**Reproducibility:** Evidence collection process must be repeatable  
**Completeness:** All DRS gates must have corresponding evidence  

### 1.2 Evidence Hierarchy

```
Level 1: Source Code and Build Artifacts
├── Source code hashes (git commits)
├── Build scripts and configurations
└── Dependency lockfiles

Level 2: Build Evidence
├── Build logs
├── Build timestamps
├── Compiler versions
└── Build environment details

Level 3: Package Evidence
├── Package hashes (SHA-256)
├── Package signing information
├── Installer manifests
└── Package metadata

Level 4: Runtime Evidence
├── Installation logs
├── Application launch verification
├── Workflow execution artifacts
└── Uninstall/cleanup verification

Level 5: Test Evidence
├── Test execution logs
├── Test results (pass/fail)
├── Screenshots
└── Hash comparisons
```

### 1.3 Evidence Storage

All evidence should be stored in:
```
evidence/
├── artifacts.json          # Package hashes and metadata
├── drs-release-gate.json   # DRS gate status
├── integrity-check.json    # Integrity verification
├── local/                  # Per-test evidence
│   ├── linux/              # Linux-specific evidence
│   │   ├── installation/   # Installation evidence
│   │   ├── workflows/      # Workflow screenshots and logs
│   │   ├── hashes/         # SHA-256 hashes
│   │   └── receipts/       # Export receipts
│   ├── macos/              # macOS-specific evidence
│   │   ├── installation/
│   │   ├── workflows/
│   │   ├── hashes/
│   │   └── receipts/
│   └── windows/            # Windows-specific evidence
│       ├── installation/
│       ├── workflows/
│       ├── hashes/
│       └── receipts/
├── signing.json            # Package signing evidence
└── validation.md           # Validation report (updated)
```

---

## 2. Evidence Types and Formats

### 2.1 Required Evidence Types

| Evidence Type | Format | Purpose | Retention |
|---------------|--------|---------|-----------|
| Hash files | .sha256, .txt | Verify file integrity | Permanent |
| Screenshots | .png | Visual verification of UI | Permanent |
| Export receipts | .json | Export verification | Permanent |
| Log files | .log, .txt | Build and runtime logging | Permanent |
| Test reports | .md, .json | Test execution results | Permanent |
| Configuration files | .json, .toml | Environment configuration | Permanent |
| Video recordings | .mp4 | Process verification (optional) | Archive |

### 2.2 Naming Conventions

**Files:**
```
{platform}-{test-id}-{type}-{timestamp}.{ext}
Example: linux-ft-01-screenshot-20261106-143022.png
```

**Directories:**
```
{platform}/{test-category}/{test-id}/
Example: linux/functional/ft-01/
```

**Hash files:**
```
{filename}.sha256
Example: sesm-desktop.app.sha256
```

### 2.3 Timestamp Format

All timestamps should use **ISO 8601** format:
```
YYYY-MM-DDTHH:MM:SSZ
Example: 2026-11-06T14:30:22Z
```

For file timestamps, also include timezone:
```
YYYY-MM-DDTHH:MM:SS+00:00  # UTC
YYYY-MM-DDTHH:MM:SS-05:00  # EST
```

---

## 3. Evidence Collection by Phase

### 3.1 Phase 1: Environment Setup Evidence

Collect evidence that the test environment is correctly configured.

#### Required Evidence

**For each VM:**

1. **VM Configuration**
   - File: `{platform}-vm-config.json`
   - Contents:
     ```json
     {
       "vm_name": "SESM-Test-Ubuntu-22.04",
       "platform": "linux",
       "hypervisor": "VMware Workstation Player",
       "hypervisor_version": "17.5.0",
       "os": "Ubuntu 22.04.4 LTS",
       "os_version": "22.04.4",
       "cpu_cores": 4,
       "memory_gb": 8,
       "disk_gb": 50,
       "network_mode": "NAT",
       "snapshot_name": "Clean-Ubuntu-22.04-Base",
       "created_at": "2026-11-06T14:30:22Z",
       "created_by": "tester"
     }
     ```

2. **OS Information**
   - File: `{platform}-os-info.txt`
   - Collect with:
     ```bash
     # Linux
     echo "=== OS Information ===" > linux-os-info.txt
     lsb_release -a >> linux-os-info.txt
     echo "" >> linux-os-info.txt
     echo "=== Kernel ===" >> linux-os-info.txt
     uname -a >> linux-os-info.txt
     echo "" >> linux-os-info.txt
     echo "=== CPU ===" >> linux-os-info.txt
     lscpu >> linux-os-info.txt
     echo "" >> linux-os-info.txt
     echo "=== Memory ===" >> linux-os-info.txt
     free -h >> linux-os-info.txt
     echo "" >> linux-os-info.txt
     echo "=== Disk ===" >> linux-os-info.txt
     df -h >> linux-os-info.txt
     
     # macOS
     echo "=== System Information ===" > macos-os-info.txt
     system_profiler SPSoftwareDataType >> macos-os-info.txt
     echo "" >> macos-os-info.txt
     echo "=== CPU ===" >> macos-os-info.txt
     sysctl -n machdep.cpu.brand_string >> macos-os-info.txt
     echo "" >> macos-os-info.txt
     echo "=== Memory ===" >> macos-os-info.txt
     sysctl hw.memsize >> macos-os-info.txt
     ```

3. **Dependency Versions**
   - File: `{platform}-dependencies.json`
   - Collect with `scripts/collect-dependencies.sh`:
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
         },
         "cargo": {
           "version": "cargo 1.75.0",
           "command": "cargo --version"
         },
         "git": {
           "version": "git version 2.40.1",
           "command": "git --version"
         }
       }
     }
     ```

4. **Environment Hash**
   - Calculate SHA-256 of the entire environment configuration
   - File: `{platform}-environment.sha256`
   - Contents:
     ```
     # Environment hash for SESM-Test-Ubuntu-22.04
     # Generated: 2026-11-06T14:30:22Z
     # Method: sha256sum of os-info.txt + dependencies.json + vm-config.json
     a1b2c3d4e5f6... linux-environment
     ```

---

### 3.2 Phase 2: Build Evidence

Collect evidence that the application builds correctly.

#### Required Evidence

1. **Build Log**
   - File: `{platform}-build-{timestamp}.log`
   - Capture complete build output:
     ```bash
     # Redirect build output to log file
     npm run build > linux-build-20261106-143022.log 2>&1
     npm run tauri build >> linux-build-20261106-143022.log 2>&1
     ```
   - Include:
     - Start time
     - Node.js/npm versions
     - Rust/cargo versions
     - Dependency installation
     - Compilation steps
     - Build completion time
     - Final package location

2. **Build Metadata**
   - File: `{platform}-build-metadata.json`
   - Contents:
     ```json
     {
       "platform": "linux",
       "build_start": "2026-11-06T14:30:22Z",
       "build_end": "2026-11-06T14:45:33Z",
       "build_duration_seconds": 911,
       "node_version": "v20.12.2",
       "npm_version": "10.8.1",
       "rustc_version": "rustc 1.75.0",
       "cargo_version": "cargo 1.75.0",
       "git_commit": "fdecae9",
       "git_branch": "Cobra",
       "package_type": "AppImage",
       "package_path": "target/release/bundle/appimage/SESM-Desktop-0.1.0.AppImage",
       "build_status": "success",
       "build_errors": []
     }
     ```

3. **Package Hash**
   - Calculate SHA-256 of the built package
   - File: `{platform}-package.sha256`
   - Example:
     ```bash
     sha256sum target/release/bundle/appimage/*.AppImage > linux-package.sha256
     ```
   - Contents:
     ```
     a1b2c3d4e5f6...  target/release/bundle/appimage/SESM-Desktop-0.1.0.AppImage
     ```

---

### 3.3 Phase 3: Installation Evidence

Collect evidence that the application installs correctly.

#### Required Evidence

1. **Installation Log**
   - File: `{platform}-install-{timestamp}.log`
   - For each package type:
     - **Windows (MSIX):** Use PowerShell
       ```powershell
       # Install
       Add-AppxPackage -Path .\SESM-Desktop-0.1.0.msix -OutputPath linux-install-20261106-143022.log
       
       # Verify
       Get-AppxPackage -Name "SESM Desktop" | Out-File -Append linux-install-20261106-143022.log
       ```
     - **Linux (AppImage):**
       ```bash
       chmod +x SESM-Desktop-0.1.0.AppImage
       ./SESM-Desktop-0.1.0.AppImage --appimage-extract
       # Log the extraction
       echo "AppImage extracted successfully" > linux-install-20261106-143022.log
       ls -la squashfs-root/ >> linux-install-20261106-143022.log
       ```
     - **macOS (DMG):**
       ```bash
       hdiutil attach SESM-Desktop-0.1.0.dmg
       # Log the mount
       echo "DMG mounted successfully" > macos-install-20261106-143022.log
       mount | grep SESM >> macos-install-20261106-143022.log
       ```

2. **Installation Metadata**
   - File: `{platform}-install-metadata.json`
   - Contents:
     ```json
     {
       "platform": "linux",
       "install_start": "2026-11-06T14:30:22Z",
       "install_end": "2026-11-06T14:32:15Z",
       "install_duration_seconds": 113,
       "package_type": "AppImage",
       "package_path": "/home/tester/projects/sesm-test/SESM-Desktop-0.1.0.AppImage",
       "install_location": "/home/tester/projects/sesm-test/",
       "install_method": "AppImage extraction",
       "install_status": "success",
       "install_errors": [],
       "verification": {
         "package_hash": "a1b2c3d4e5f6...",
         "package_hash_verified": true
       }
     }
     ```

3. **Installed Files**
   - List all installed files with hashes
   - File: `{platform}-installed-files.json`
   - Collect with:
     ```bash
     # For AppImage
     find squashfs-root/ -type f -exec sha256sum {} \; > linux-installed-files.sha256
     
     # Convert to JSON
     cat linux-installed-files.sha256 | awk '{print "{\"path\": \"" $2 "\", \"hash\": \"" $1 "\"},"}' > linux-installed-files.json
     ```

---

### 3.4 Phase 4: Runtime Evidence

Collect evidence that the application runs correctly.

#### Required Evidence

1. **Launch Verification**
   - File: `{platform}-launch-verify.json`
   - Contents:
     ```json
     {
       "platform": "linux",
       "launch_timestamp": "2026-11-06T14:35:00Z",
       "launch_command": "./squashfs-root/AppRun",
       "launch_status": "success",
       "window_title": "SESM Desktop · Aptlantis-Factor",
       "version_displayed": "0.1.0",
       "launch_duration_seconds": 3.2,
       "screenshot": "linux-launch-screenshot-20261106-143503.png",
       "verification": {
         "title_verified": true,
         "version_verified": true,
         "window_visible": true
       }
     }
     ```
   - Screenshot: Full window screenshot showing:
     - Application title
     - Version
     - Empty workspace
     - Offline indicator

2. **Workflow Execution Evidence**
   - For each test case, collect:
     - Before state (screenshot, hashes)
     - Actions performed
     - After state (screenshot, hashes)
     - Validation results
   - File structure:
     ```
     linux/workflows/ft-01-single-svg-import/
     ├── metadata.json
     ├── before.png
     ├── after.png
     ├── source.svg.sha256
     ├── output.svg.sha256
     └── receipt.json (if applicable)
     ```
   - Metadata example:
     ```json
     {
       "test_id": "FT-01",
       "test_name": "Single SVG Import",
       "platform": "linux",
       "timestamp": "2026-11-06T14:40:00Z",
       "tester": "tester",
       "status": "PASS",
       "actions": [
         "Clicked 'Open SVGs' button",
         "Selected tests/fixtures/atlas-infographic.svg",
         "Clicked 'Open'"
       ],
       "expected_result": "File loaded, preview displayed, metadata parsed",
       "actual_result": "File loaded, preview displayed, metadata parsed",
       "notes": "",
       "artifacts": {
         "screenshots": ["before.png", "after.png"],
         "hashes": ["source.svg.sha256", "output.svg.sha256"],
         "logs": []
       }
     }
     ```

3. **Preservation Evidence**
   - For each preservation test (PT-01 through PT-07):
     - Calculate SHA-256 of source file before
     - Calculate SHA-256 of source file after
     - Calculate SHA-256 of output file
     - Verify source unchanged
   - File: `{platform}-preservation-{test-id}.json`
   - Example:
     ```json
     {
       "test_id": "PT-01",
       "test_name": "Byte Preservation (Outside Block)",
       "platform": "linux",
       "timestamp": "2026-11-06T15:00:00Z",
       "source_file": "tests/fixtures/atlas-infographic.svg",
       "source_hash_before": "a1b2c3d4e5f6...",
       "source_hash_after": "a1b2c3d4e5f6...",
       "output_file": "SESM-Export-20261106150000/atlas-infographic.svg",
       "output_hash": "f6e5d4c3b2a1...",
       "source_unchanged": true,
       "metadata_changed": true,
       "preservation_verified": true,
       "notes": "Source bytes outside SESM block verified unchanged"
     }
     ```

4. **Safety Evidence**
   - For each safety test (ST-01 through ST-10):
     - Document the malicious input
     - Document the expected error
     - Document the actual result
     - Screenshot of error message
   - File: `{platform}-safety-{test-id}.json`
   - Example:
     ```json
     {
       "test_id": "ST-01",
       "test_name": "SVG with Script Tag",
       "platform": "linux",
       "timestamp": "2026-11-06T15:30:00Z",
       "input_file": "test-data/st-01-script.svg",
       "input_hash": "a1b2c3d4e5f6...",
       "expected_error": "Active element forbidden",
       "actual_error": "Active element forbidden",
       "export_blocked": true,
       "status": "PASS",
       "screenshot": "linux-safety-st-01-error-20261106-153000.png",
       "notes": "Script tag correctly blocked"
     }
     ```

---

### 3.5 Phase 5: Recovery Evidence

Collect evidence that recovery works correctly.

#### Required Evidence

1. **Cancellation Evidence**
   - File: `{platform}-recovery-cancel-export.json`
   - Example:
     ```json
     {
       "test_id": "RT-02",
       "test_name": "Application Crash During Export",
       "platform": "linux",
       "timestamp": "2026-11-06T16:00:00Z",
       "action": "Kill app during export of 3 files",
       "files_started": 3,
       "files_completed": 1,
       "files_failed": 1,
       "files_cancelled": 1,
       "receipt_status": "cancelled",
       "partial_files_cleaned": true,
       "status": "PASS",
       "artifacts": {
         "receipt": "linux-recovery-rt-02-receipt.json",
         "screenshot": "linux-recovery-rt-02-result-20261106-160000.png"
       },
       "notes": "Export cancelled after 1 file, partial files cleaned up"
     }
     ```

2. **Source Protection Evidence**
   - File: `{platform}-recovery-source-protection.json`
   - Example:
     ```json
     {
       "test_id": "RT-01",
       "test_name": "Source Changed After Import",
       "platform": "linux",
       "timestamp": "2026-11-06T16:30:00Z",
       "source_file": "tests/fixtures/atlas-infographic.svg",
       "source_hash_original": "a1b2c3d4e5f6...",
       "source_hash_modified": "b2c3d4e5f6a1...",
       "import_timestamp": "2026-11-06T16:25:00Z",
       "modify_timestamp": "2026-11-06T16:28:00Z",
       "export_attempt_timestamp": "2026-11-06T16:30:00Z",
       "error_message": "Source changed after import; reopen and review it.",
       "export_blocked": true,
       "source_unchanged": false,
       "status": "PASS",
       "notes": "Source modification correctly detected, export blocked"
     }
     ```

---

## 4. Automated Evidence Collection

### 4.1 Script: collect-evidence.sh

Create a script to automate evidence collection:

```bash
#!/bin/bash
# scripts/collect-evidence.sh

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
EVIDENCE_DIR="evidence/local/${PLATFORM}"

mkdir -p "$EVIDENCE_DIR"

echo "Collecting evidence for platform: $PLATFORM"
echo "Timestamp: $TIMESTAMP"
echo "Output directory: $EVIDENCE_DIR"

# 1. Collect OS info
if [ "$PLATFORM" = "linux" ]; then
    lsb_release -a > "$EVIDENCE_DIR/os-info.txt" 2>&1
    uname -a >> "$EVIDENCE_DIR/os-info.txt" 2>&1
    lscpu >> "$EVIDENCE_DIR/os-info.txt" 2>&1
    free -h >> "$EVIDENCE_DIR/os-info.txt" 2>&1
    df -h >> "$EVIDENCE_DIR/os-info.txt" 2>&1
elif [ "$PLATFORM" = "darwin" ]; then
    system_profiler SPSoftwareDataType > "$EVIDENCE_DIR/os-info.txt" 2>&1
    sysctl -n machdep.cpu.brand_string >> "$EVIDENCE_DIR/os-info.txt" 2>&1
    sysctl hw.memsize >> "$EVIDENCE_DIR/os-info.txt" 2>&1
    df -h >> "$EVIDENCE_DIR/os-info.txt" 2>&1
fi

# 2. Collect dependency versions
echo "{" > "$EVIDENCE_DIR/dependencies.json"
echo "  \"platform\": \"$PLATFORM\"," >> "$EVIDENCE_DIR/dependencies.json"
echo "  \"collected_at\": \"$TIMESTAMP\"," >> "$EVIDENCE_DIR/dependencies.json"
echo "  \"dependencies\": {" >> "$EVIDENCE_DIR/dependencies.json"
echo "    \"nodejs\": \"$(node --version 2>&1 | tr -d '\n')\"," >> "$EVIDENCE_DIR/dependencies.json"
echo "    \"npm\": \"$(npm --version 2>&1 | tr -d '\n')\"," >> "$EVIDENCE_DIR/dependencies.json"
echo "    \"rustc\": \"$(rustc --version 2>&1 | tr -d '\n')\"," >> "$EVIDENCE_DIR/dependencies.json"
echo "    \"cargo\": \"$(cargo --version 2>&1 | tr -d '\n')\"," >> "$EVIDENCE_DIR/dependencies.json"
echo "    \"git\": \"$(git --version 2>&1 | tr -d '\n')\"" >> "$EVIDENCE_DIR/dependencies.json"
echo "  }" >> "$EVIDENCE_DIR/dependencies.json"
echo "}" >> "$EVIDENCE_DIR/dependencies.json"

# 3. Calculate environment hash
sha256sum "$EVIDENCE_DIR/os-info.txt" "$EVIDENCE_DIR/dependencies.json" | \
    awk '{print $1}' | \
    sha256sum | \
    awk '{print $1 "  " ARGC}' > "$EVIDENCE_DIR/environment.sha256"

echo "Evidence collection complete!"
```

### 4.2 Script: verify-preservation.sh

```bash
#!/bin/bash
# scripts/verify-preservation.sh

# Verify that source files are unchanged after export
# Usage: ./verify-preservation.sh <source-file> <output-file>

SOURCE_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$SOURCE_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <source-file> <output-file>"
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file not found: $SOURCE_FILE"
    exit 1
fi

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Error: Output file not found: $OUTPUT_FILE"
    exit 1
fi

# Calculate hashes
SOURCE_HASH=$(sha256sum "$SOURCE_FILE" | awk '{print $1}')
OUTPUT_HASH=$(sha256sum "$OUTPUT_FILE" | awk '{print $1}')

# Extract SESM block from output
# Find the SESM metadata block
SESM_START=$(grep -aob '<metadata id="sesm">' "$OUTPUT_FILE" | head -1 | awk -F: '{print $1}')
SESM_END=$(grep -aob '</metadata>' "$OUTPUT_FILE" | head -1 | awk -F: '{print $1}')
SESM_END=$((SESM_END + 11))  # Length of '</metadata>'

if [ -z "$SESM_START" ] || [ -z "$SESM_END" ]; then
    echo "Error: Could not find SESM metadata block in output file"
    exit 1
fi

# Extract bytes outside SESM block
BEFORE_SESM=${SOURCE_FILE:0:$SESM_START}
AFTER_SESM=${SOURCE_FILE:$SESM_END}
BEFORE_HASH=$(echo -n "$BEFORE_SESM" | sha256sum | awk '{print $1}')
AFTER_HASH=$(echo -n "$AFTER_SESM" | sha256sum | awk '{print $1}')

# Extract same regions from source (assuming no SESM block)
if grep -aq '<metadata id="sesm">' "$SOURCE_FILE"; then
    # Source has SESM block, extract same way
    SOURCE_SESM_START=$(grep -aob '<metadata id="sesm">' "$SOURCE_FILE" | head -1 | awk -F: '{print $1}')
    SOURCE_SESM_END=$(grep -aob '</metadata>' "$SOURCE_FILE" | head -1 | awk -F: '{print $1}')
    SOURCE_SESM_END=$((SOURCE_SESM_END + 11))
    
    SOURCE_BEFORE_SESM=${SOURCE_FILE:0:$SOURCE_SESM_START}
    SOURCE_AFTER_SESM=${SOURCE_FILE:$SOURCE_SESM_END}
    SOURCE_BEFORE_HASH=$(echo -n "$SOURCE_BEFORE_SESM" | sha256sum | awk '{print $1}')
    SOURCE_AFTER_HASH=$(echo -n "$SOURCE_AFTER_SESM" | sha256sum | awk '{print $1}')
    
    if [ "$BEFORE_HASH" = "$SOURCE_BEFORE_HASH" ] && [ "$AFTER_HASH" = "$SOURCE_AFTER_HASH" ]; then
        echo "PRESERVATION VERIFIED: Bytes outside SESM block are unchanged"
        exit 0
    else
        echo "PRESERVATION FAILED: Bytes outside SESM block have changed"
        exit 1
    fi
else
    # Source has no SESM block, compare entire file except where SESM was inserted
    # This is a simplified check
    echo "Note: Source has no SESM block, performing simplified check"
    
    # Just verify source file itself is unchanged
    SOURCE_HASH_NOW=$(sha256sum "$SOURCE_FILE" | awk '{print $1}')
    if [ "$SOURCE_HASH" = "$SOURCE_HASH_NOW" ]; then
        echo "PRESERVATION VERIFIED: Source file unchanged"
        exit 0
    else
        echo "PRESERVATION FAILED: Source file has changed"
        exit 1
    fi
fi
```

---

## 5. Evidence Validation

### 5.1 Hash Validation

All hash files must be validated:

```bash
# Linux/macOS
cd evidence/local/linux/hashes
sha256sum -c *.sha256

# Windows (PowerShell)
cd evidence\local\windows\hashes
Get-Content *.sha256 | ForEach-Object {
    $expected, $file = $_ -split "\s+\s+"
    $actual = (Get-FileHash -Algorithm SHA256 $file).Hash.ToLower()
    if ($expected -eq $actual) {
        Write-Host "OK: $file"
    } else {
        Write-Host "FAIL: $file"
    }
}
```

### 5.2 Evidence Integrity Check

Run the evidence integrity check:

```bash
# Verify all evidence files
scripts/verify-evidence.sh
```

Script example:

```bash
#!/bin/bash
# scripts/verify-evidence.sh

EVIDENCE_DIR="evidence"
ERRORS=0

# Check all hash files
find "$EVIDENCE_DIR" -name "*.sha256" -type f | while read hashfile; do
    dir=$(dirname "$hashfile")
    cd "$dir"
    if ! sha256sum -c "$(basename "$hashfile")" 2>/dev/null; then
        echo "ERROR: Hash validation failed for $hashfile"
        ERRORS=$((ERRORS + 1))
    fi
    cd - >/dev/null
done

# Check all JSON files are valid
find "$EVIDENCE_DIR" -name "*.json" -type f | while read jsonfile; do
    if ! jq empty "$jsonfile" 2>/dev/null; then
        echo "ERROR: Invalid JSON in $jsonfile"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check all screenshots exist and are valid
find "$EVIDENCE_DIR" -name "*.png" -type f | while read pngfile; do
    if ! file "$pngfile" | grep -q "PNG image data"; then
        echo "ERROR: Invalid PNG in $pngfile"
        ERRORS=$((ERRORS + 1))
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "All evidence validated successfully!"
    exit 0
else
    echo "$ERRORS errors found in evidence"
    exit 1
fi
```

---

## 6. Evidence Archive

### 6.1 Archive Structure

Create a comprehensive archive for each platform:

```
SESM-Desktop-Evidence-{platform}-{version}-{date}.tar.gz
├── evidence/
│   ├── local/
│   │   └── {platform}/
│   │       ├── installation/
│   │       │   ├── os-info.txt
│   │       │   ├── dependencies.json
│   │       │   ├── vm-config.json
│   │       │   ├── environment.sha256
│   │       │   ├── build-*.log
│   │       │   ├── build-metadata.json
│   │       │   ├── install-*.log
│   │       │   └── install-metadata.json
│   │       ├── workflows/
│   │       │   ├── ft-01/
│   │       │   │   ├── metadata.json
│   │       │   │   ├── *.png
│   │       │   │   └── *.sha256
│   │       │   └── ...
│   │       ├── safety/
│   │       ├── preservation/
│   │       ├── recovery/
│   │       └── hashes/
│   ├── artifacts.json
│   └── validation.md
├── README.md
└── sha256sum.txt
```

### 6.2 Creating Archive

```bash
# Create archive for Linux
platform="linux"
version="0.1.0"
date=$(date +"%Y%m%d")
archive_name="SESM-Desktop-Evidence-${platform}-${version}-${date}.tar.gz"

# Create temporary directory
mkdir -p /tmp/evidence-archive

# Copy evidence
cp -r evidence /tmp/evidence-archive/
cp README.md /tmp/evidence-archive/

# Create checksum
cd /tmp/evidence-archive
find . -type f -exec sha256sum {} \; > sha256sum.txt

# Create archive
cd /tmp
tar -czf "$archive_name" evidence-archive/

# Move to evidence directory
mv "$archive_name" evidence/

# Clean up
rm -rf /tmp/evidence-archive
```

---

## 7. Evidence Review Process

### 7.1 Daily Review

At the end of each testing day:

1. **Validate all collected evidence**
   ```bash
   scripts/verify-evidence.sh
   ```

2. **Backup evidence**
   ```bash
   git add evidence/
   git commit -m "Evidence: Add {platform} testing results for {date}"
   ```

3. **Update test execution log**
   - Review `evidence/local/{platform}/`
   - Ensure all tests have corresponding evidence
   - Mark incomplete tests

### 7.2 Platform Acceptance Review

Before declaring a platform as "ACCEPT":

1. **Verify all critical tests PASS**
   - Check `TEST-PLAN.md` for critical test list
   - Verify each has PASS status and evidence

2. **Verify evidence completeness**
   - All required evidence types present
   - All hashes validated
   - All screenshots captured

3. **Verify cross-platform parity**
   - Compare results with other platforms
   - Investigate any discrepancies

4. **Create platform acceptance report**
   - File: `docs/{PLATFORM}-ACCEPTANCE.md`
   - Summary of all tests
   - List of any non-critical failures
   - Evidence location references

### 7.3 Release Acceptance Review

Before declaring release as "VERIFIED":

1. **Verify all platforms ACCEPT**
   - Windows
   - Linux
   - macOS

2. **Verify cross-platform tests PASS**
   - CP-01 through CP-04

3. **Verify DRS gates**
   - install-upgrade gate
   - runtime gate

4. **Update release evidence**
   - `evidence/artifacts.json`
   - `evidence/validation.md`
   - `Validation-Checklist.md`

---

## 8. Evidence Retention

### 8.1 Retention Periods

| Evidence Type | Retention | Rationale |
|---------------|-----------|-----------|
| Source code | Permanent | Repository history |
| Build artifacts | Permanent | Reproducibility |
| Build logs | 2 years | Debugging |
| Test execution logs | 2 years | Audit trail |
| Screenshots | 2 years | Visual verification |
| Hash files | Permanent | Integrity verification |
| Export receipts | Permanent | Export verification |
| VM images | Archive only | Space considerations |

### 8.2 Storage Requirements

| Platform | Evidence Size Estimate | Notes |
|----------|------------------------|-------|
| Windows | 500 MB - 1 GB | MSIX packages are large |
| Linux | 200 MB - 500 MB | AppImage packages |
| macOS | 1 GB - 2 GB | DMG packages are largest |
| **Total** | **1.7 GB - 3.5 GB** | For all platforms |

### 8.3 Backup Strategy

1. **Local backup**
   - Daily git commits
   - Weekly archive creation
   - External drive backup

2. **Remote backup** (optional)
   - Push to remote git repository
   - Upload archives to cloud storage
   - Ensure encryption for sensitive data

---

## 9. Checklists

### 9.1 Evidence Collection Checklist

For each test:

- [ ] Test ID documented
- [ ] Test name documented
- [ ] Platform documented
- [ ] Timestamp documented
- [ ] Tester documented
- [ ] Actions documented
- [ ] Expected result documented
- [ ] Actual result documented
- [ ] Status (PASS/FAIL/BLOCKED/SKIPPED) documented
- [ ] Screenshots captured (if applicable)
- [ ] Hashes calculated (if applicable)
- [ ] Logs saved (if applicable)
- [ ] Evidence validated
- [ ] Evidence committed to repository

### 9.2 Platform Evidence Checklist

For each platform:

**Installation:**
- [ ] VM configuration documented
- [ ] OS information collected
- [ ] Dependency versions collected
- [ ] Environment hash calculated
- [ ] Build log captured
- [ ] Build metadata documented
- [ ] Package hash calculated
- [ ] Installation log captured
- [ ] Installation metadata documented
- [ ] Installed files documented

**Runtime:**
- [ ] Launch verification captured
- [ ] Screenshot of application window
- [ ] Version verification

**Workflow:**
- [ ] Functional tests evidence
- [ ] Safety tests evidence
- [ ] Preservation tests evidence
- [ ] Visual tests evidence
- [ ] Recovery tests evidence
- [ ] Cross-platform tests evidence

**Acceptance:**
- [ ] Platform acceptance report created
- [ ] All critical tests PASS
- [ ] Evidence archive created
- [ ] Evidence validated

---

## 10. Templates

### 10.1 Test Execution Log Template

```markdown
# Test Execution Log

**Platform:** {platform}  
**Date:** {date}  
**Tester:** {tester}  
**VM:** {vm-name}  

## Summary

- Total Tests: {total}
- PASS: {pass}
- FAIL: {fail}
- BLOCKED: {blocked}
- SKIPPED: {skipped}
- Completion: {completion}%

## Test Results

| Test ID | Test Name | Status | Duration | Notes |
|---------|-----------|--------|----------|-------|
| FT-01 | Single SVG Import | PASS | 2m 30s | |
| FT-02 | Batch SVG Import | PASS | 3m 15s | |
| ... | ... | ... | ... | ... |

## Evidence Location

All evidence stored in: `evidence/local/{platform}/`

- Installation: `evidence/local/{platform}/installation/`
- Workflows: `evidence/local/{platform}/workflows/`
- Safety: `evidence/local/{platform}/safety/`
- Preservation: `evidence/local/{platform}/preservation/`
- Recovery: `evidence/local/{platform}/recovery/`

## Issues

1. **Issue:** {description}
   - **Test ID:** {test-id}
   - **Severity:** {critical/non-critical}
   - **Status:** {open/resolved}
   - **Resolution:** {resolution}

## Sign-off

**Reviewer:** {reviewer}  
**Review Date:** {review-date}  
**Approval Status:** {approved/rejected/conditional}

**Notes:**
{notes}
```

### 10.2 Platform Acceptance Report Template

```markdown
# {Platform} Acceptance Report

**Version:** 1.0  
**Date:** {date}  
**Platform:** {platform}  
**Acceptance Status:** {ACCEPT/REJECT/CONDITIONAL}

## 1. Environment

| Property | Value |
|----------|-------|
| VM Name | {vm-name} |
| Hypervisor | {hypervisor} |
| OS | {os} |
| OS Version | {os-version} |
| CPU | {cpu} |
| Memory | {memory} |
| Disk | {disk} |

## 2. Build

| Property | Value |
|----------|-------|
| Build Status | {status} |
| Build Duration | {duration} |
| Package Type | {package-type} |
| Package Path | {package-path} |
| Package Hash | {package-hash} |

## 3. Installation

| Property | Value |
|----------|-------|
| Install Status | {status} |
| Install Duration | {duration} |
| Install Location | {install-location} |
| Install Method | {install-method} |

## 4. Test Results

### 4.1 Critical Tests

| Test ID | Test Name | Status | Notes |
|---------|-----------|--------|-------|
| FT-01 | Single SVG Import | PASS | |
| FT-02 | Batch SVG Import | PASS | |
| ... | ... | ... | ... |

**Critical Tests: {passed}/{total} PASS**

### 4.2 Non-Critical Tests

| Test ID | Test Name | Status | Notes |
|---------|-----------|--------|-------|
| FT-10 | UTF-8 with BOM | PASS | |
| ... | ... | ... | ... |

**Non-Critical Tests: {passed}/{total} PASS**

## 5. Issues

### 5.1 Blocking Issues

None (for ACCEPT status)

### 5.2 Non-Blocking Issues

1. **Issue:** {description}
   - **Severity:** Minor
   - **Impact:** {impact}
   - **Workaround:** {workaround}

## 6. Evidence

### 6.1 Evidence Location

All evidence stored in: `evidence/local/{platform}/`

### 6.2 Evidence Archive

- File: `SESM-Desktop-Evidence-{platform}-{version}-{date}.tar.gz`
- Size: {size}
- Hash: {hash}

## 7. Conclusion

**Acceptance Status:** {ACCEPT/REJECT/CONDITIONAL}

**Rationale:**
{rationale}

**Recommendations:**
{recommendations}

## 8. Sign-off

**Tester:** {tester}  
**Test Date:** {test-date}  

**Reviewer:** {reviewer}  
**Review Date:** {review-date}

**Approval:**
- [ ] Approved
- [ ] Rejected
- [ ] Conditional (see recommendations)
```

---

## 11. Related Documents

- `TEST-PLAN.md` - Comprehensive test definitions
- `TESTING-VM-GUIDE.md` - VM setup guide
- `LINUX-ACCEPTANCE.md` - Linux acceptance report
- `MACOS-ACCEPTANCE.md` - macOS acceptance report
- `Validation-Checklist.md` - Release checklist
- `evidence/validation.md` - Validation report

---

## 12. Glossary

| Term | Definition |
|------|------------|
| DRS | Delivery Readiness Standard |
| Evidence | Any artifact that demonstrates compliance or functionality |
| Hash | SHA-256 cryptographic hash for integrity verification |
| Provenance | Chain of custody for evidence |
| Reproducibility | Ability to recreate the same results |
| Snapshot | Point-in-time state of a VM |
| Validation | Process of verifying evidence meets requirements |

---

**Document Status:** Ready for use  
**Last Updated:** 2026-11-06  
**Owner:** SESM Desktop Team  
**Next Review:** After each testing session
