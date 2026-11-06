# SESM Desktop v0.1.0 — Cross-Platform Acceptance Test Plan

**Document Version:** 1.0  
**Date:** 2026-11-06  
**Status:** Implementation Candidate  
**Target:** Release Readiness Validation (DRS Phase 4)

---

## 1. Overview

This document defines the comprehensive test plan for validating SESM Desktop v0.1.0 across all target platforms (Windows, Linux, macOS). The plan covers functional verification, safety validation, preservation guarantees, and recovery testing required for DRS release acceptance.

### 1.1 Objectives

- Verify core workflows on all target platforms
- Validate byte-preserving metadata embedding
- Confirm safety and security boundaries
- Test recovery and cancellation scenarios
- Collect credible cross-platform evidence
- Achieve DRS "install-upgrade" and "runtime" gate completion

### 1.2 Scope

**In Scope:**
- All features defined in Project-Proposal.md and Roadmap.md
- All workflows described in README.md
- All validation categories (XML, schema, safe-profile, privacy, integrity)
- Cross-platform parity testing

**Out of Scope:**
- Optional Aptlantis pipeline integration
- Chromatic Atlas integration
- Directory monitoring
- AI assistance features
- Public publication channels

### 1.3 Test Levels

| Level | Type | Count | Purpose |
|-------|------|-------|---------|
| L1 | Engine Unit Tests | 18 | Rust crate validation |
| L2 | Frontend Unit Tests | 4 | TypeScript model validation |
| L3 | Browser Workflow Tests | 4 | Frontend contract validation |
| L4 | Acceptance Tests | 25 | Platform-specific workflow validation |
| L5 | Regression Tests | 8 | Known failure mode verification |

---

## 2. Test Environment

### 2.1 Platform Matrix

| Platform | OS Version | Architecture | Environment | Build Command |
|----------|-------------|--------------|-------------|---------------|
| Windows | Windows 10/11 | x86_64 | Native/MSVC | `npm run tauri build` |
| Linux | Ubuntu 22.04 LTS | x86_64 | Native/GNU | `npm run tauri build` |
| Linux | Ubuntu 22.04 LTS | x86_64 | VM/VMware | `npm run tauri build` |
| macOS | macOS 13+ (Ventura) | arm64 | Native/Xcode | `npm run tauri build` |
| macOS | macOS 13+ (Ventura) | arm64 | VM/UTM | `npm run tauri build` |

### 2.2 Prerequisites

#### Common to All Platforms
- Node.js 20+ (LTS recommended)
- npm 10+
- Git 2.x
- Rust 1.75+ (stable toolchain)
- Cargo 1.75+

#### Windows-Specific
- Visual Studio 2022 (MSVC toolchain)
- Windows 10/11 SDK
- WebView2 Runtime

#### Linux-Specific
- GCC 11+ or Clang 14+
- libwebkit2gtk-4.1 (WebKitGTK)
- libgtk-3-dev
- libayatana-appindicator3-dev
- pkg-config
- libssl-dev

#### macOS-Specific
- Xcode 14.3+
- Xcode Command Line Tools
- macOS SDK 13.3+

### 2.3 VM Configuration

See `TESTING-VM-GUIDE.md` for detailed VM setup instructions.

---

## 3. Test Categories

### 3.1 Functional Tests (L4)

#### 3.1.1 Import and Analysis

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| FT-01 | Single SVG Import | Open one SVG file via native picker | File loaded, preview displayed, metadata parsed |
| FT-02 | Batch SVG Import | Open multiple SVG files (5-10) | All files loaded, each with unique ID |
| FT-03 | SVG with Existing SESM | Open SVG with valid SESM 0.3.0 block | Metadata extracted, version detected |
| FT-04 | SVG with SESM 0.2.0 | Open SVG with SESM 0.2.0 block | Compatible mode, metadata extracted |
| FT-05 | SVG without SESM | Open SVG without metadata block | Default SESM 0.3.0 draft created |
| FT-06 | Large SVG (4.9 MiB) | Open SVG near max size limit | Loads successfully, validation passes |
| FT-07 | SVG at Max Size (5 MiB) | Open SVG at exact limit | Loads successfully |
| FT-08 | SVG over Max Size | Attempt to open SVG > 5 MiB | Error: "SVG exceeds 5 MiB" |
| FT-09 | UTF-8 with BOM | Open SVG with UTF-8 BOM | Loads successfully, BOM preserved in output |
| FT-10 | UTF-8 with CRLF | Open SVG with CRLF line endings | Loads successfully, CRLF preserved in output |

#### 3.1.2 Metadata Editing

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| FT-11 | Structured Field Edit | Edit asset/title field via form | Change reflected in draft and preview |
| FT-12 | JSON Field Edit | Edit raw JSON directly | Valid JSON accepted, model updated |
| FT-13 | Arbitrary Precision | Edit field with large integer (9007199254740993123456789) | Value preserved exactly in output |
| FT-14 | Decimal Precision | Edit field with high-precision decimal | Value preserved exactly in output |
| FT-15 | Add New Field | Add custom field not in schema | Field preserved in output |
| FT-16 | Remove Field | Delete a field via form | Field removed from metadata |
| FT-17 | Nested Object Edit | Edit nested object path | Change applied correctly |
| FT-18 | Array Edit | Edit array field | Array preserved in output |
| FT-19 | Invalid JSON Input | Enter malformed JSON | Error displayed, last valid model retained |
| FT-20 | Duplicate Key Input | Enter JSON with duplicate keys | Error displayed, export blocked |

#### 3.1.3 Validation

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| FT-21 | Valid Metadata | Validate correct SESM 0.3.0 JSON | Profile: sesm-safe, exportable: true |
| FT-22 | Schema Error | Validate invalid SESM schema | Profile: sesm-unverified, exportable: false |
| FT-23 | Warning Only | Validate with warnings (external refs) | Profile: sesm-unverified, exportable: true with acknowledgement |
| FT-24 | Safety Error | Validate with safety error (script tag) | Profile: sesm-unsafe, exportable: false |
| FT-25 | Privacy Warning | Validate with privacy warning (path in value) | Warning displayed, acknowledgement required |

#### 3.1.4 Templates

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| FT-26 | Save Template | Save current metadata as template | Template saved to app data, appears in list |
| FT-27 | Apply Template (No Conflicts) | Apply template to file with no overlapping fields | Missing fields filled, existing preserved |
| FT-28 | Apply Template (With Conflicts) | Apply template to file with overlapping fields | Conflicts displayed, existing values preserved |
| FT-29 | Apply Template (Selective Overwrite) | Apply template with selected overwrite paths | Selected paths overwritten, others preserved |
| FT-30 | Delete Template | Delete a saved template | Template removed from list |

#### 3.1.5 Approval and Export

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| FT-31 | Approve Single File | Approve one valid file | Status: approved, ready for export |
| FT-32 | Approve with Warnings | Approve file with warnings, acknowledged | Status: approved, warnings_acknowledged: true |
| FT-33 | Approve with Errors | Attempt to approve file with errors | Error: "Resolve validation errors before approving" |
| FT-34 | Approve Changed Draft | Change draft after approval, re-approve | New revision approved |
| FT-35 | Export Single File | Export one approved file | New folder created, SVG copy with metadata, receipt generated |
| FT-36 | Export Multiple Files | Export multiple approved files | All files exported to same folder, single receipt |
| FT-37 | Export with Warnings | Export file with acknowledged warnings | File exported, warnings recorded in receipt |
| FT-38 | Export No Approved Files | Attempt export with no approved files | Error: "Approve at least one file before exporting" |
| FT-39 | Export to Existing Folder | Attempt export to existing destination | Error: "Choose a new destination folder" |
| FT-40 | Cancel Export | Start export, then cancel | Partial files cleaned up, receipt shows cancelled status |

### 3.2 Safety and Security Tests (L4)

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| ST-01 | SVG with Script Tag | Open SVG containing `<script>` element | Error: Active element forbidden, export blocked |
| ST-02 | SVG with Event Handler | Open SVG with onload attribute | Error: Executable attribute forbidden, export blocked |
| ST-03 | SVG with ForeignObject | Open SVG with `<foreignObject>` | Error: Active element forbidden, export blocked |
| ST-04 | SVG with DTD | Open SVG with DOCTYPE | Error: DTDs not supported, export blocked |
| ST-05 | SVG with External Entity | Open SVG with external entity reference | Error: DTDs/external entities not supported, export blocked |
| ST-06 | SVG with JavaScript URL | Open SVG with href="javascript:..." | Error: Executable URL forbidden, export blocked |
| ST-07 | SVG with CSS Expression | Open SVG with CSS expression() | Error: Executable CSS forbidden, export blocked |
| ST-08 | SVG with Nested SVG | Open SVG with nested `<svg>` in image href | Error: Nested SVG not supported, export blocked |
| ST-09 | Multiple SESM Blocks | Open SVG with duplicate SESM metadata blocks | Error: Multiple SESM blocks are ambiguous, export blocked |
| ST-10 | SESM with Child Elements | Open SVG with SESM metadata containing XML children | Error: SESM must contain JSON text, export blocked |

### 3.3 Preservation Tests (L4)

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| PT-01 | Byte Preservation (Outside Block) | Edit metadata, compare bytes outside SESM range | Original bytes exactly preserved |
| PT-02 | Line Ending Preservation | Edit metadata in file with CRLF | Output maintains CRLF |
| PT-03 | BOM Preservation | Edit metadata in file with BOM | Output maintains BOM |
| PT-04 | Unknown Field Preservation | Add/remove fields, keep unknown field | Unknown field preserved in output |
| PT-05 | Arbitrary Precision Preservation | Edit other fields, keep high-precision number | High-precision number preserved exactly |
| PT-06 | CDATA Delimiter Preservation | Metadata containing `]]>` | CDATA delimiters escaped correctly |
| PT-07 | Namespaced SVG | Edit metadata in namespaced SVG (`<s:svg>`) | Namespace prefix preserved in output |

### 3.4 Visual Preservation Tests (L4)

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| VT-01 | Raster Comparison | Edit metadata, compare before/after previews | Raster output identical (PNG data URL match) |
| VT-02 | CSS First-Child Regression | Edit SVG with `:first-child` selector | Export blocked if appearance changes |
| VT-03 | Embedded Raster Preview | Open SVG with embedded PNG | Preview displays raster image |
| VT-04 | Unsupported Embedded Raster | Open SVG with embedded SVG in data URL | Error: Embedded payload not supported |

### 3.5 Recovery and Edge Case Tests (L4)

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| RT-01 | Source Changed After Import | Modify source file after import, attempt export | Error: "Source changed after import; reopen and review" |
| RT-02 | Application Crash During Export | Kill app during export | Partial files cleaned up, receipt shows status |
| RT-03 | Disk Full During Export | Fill disk during export | Error in receipt, partial files removed |
| RT-04 | Permission Denied During Export | Export to read-only location | Error in receipt, no files written |
| RT-05 | Close Without Saving | Edit draft, attempt to close | Warning: "Close and discard unexported edits?" |
| RT-06 | Reopen After Crash | Crash app with open files, reopen | Files must be reimported (no autosave) |
| RT-07 | Non-Unicode Filename | Attempt to open file with non-Unicode name | Error: "Filename must be Unicode" |
| RT-08 | Reserved Filename (Windows) | Attempt to export file named CON.svg | Error: "Filename is not portable" |
| RT-09 | Case-Insensitive Collision | Export files with case-only name differences | Error: "Case-insensitive filename collision" |

### 3.6 Cross-Platform Parity Tests (L4)

| ID | Test | Description | Expected Result |
|----|------|-------------|-----------------|
| CP-01 | Same SVG on All Platforms | Open same SVG file on Windows, Linux, macOS | Identical analysis, validation, and output |
| CP-02 | Same Template on All Platforms | Apply same template on all platforms | Identical metadata result |
| CP-03 | Export Hash Consistency | Export same SVG on all platforms | Identical output SHA-256 hash |
| CP-04 | Preview Consistency | Generate preview on all platforms | Identical PNG output (within renderer tolerance) |

---

## 4. Regression Tests (L5)

These tests verify that known failure modes are properly handled:

| ID | Test | Failure Mode | Expected Behavior |
|----|------|---------------|-------------------|
| RG-01 | Deep XML Nesting | XML depth > 128 | Error: "XML nesting exceeds 128 levels" |
| RG-02 | Oversized Metadata | Metadata > 64 KiB | Error: "SESM JSON exceeds 64 KiB" |
| RG-03 | Oversized SVG | SVG > 5 MiB | Error: "SVG exceeds 5 MiB" |
| RG-04 | Oversized Preview | SVG renders > 16 megapixels | Error: "Preview exceeds 16 megapixels" |
| RG-05 | Invalid UTF-8 | SVG with invalid UTF-8 | Error: "Only UTF-8 SVGs are supported" |
| RG-06 | Non-SVG Root | XML with non-svg root | Error: "Root element must be SVG" |
| RG-07 | Multiple SESM Blocks | SVG with duplicate SESM | Error: "Multiple SESM blocks are ambiguous" |
| RG-08 | Structural CSS Change | Metadata insertion affects CSS | Export blocked: "rendered appearance changes" |

---

## 5. Test Execution

### 5.1 Test Environment Setup

```bash
# Common setup (all platforms)
git clone https://github.com/aptlantis/SESM-Desktop.git
cd SESM-Desktop
npm ci

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Platform-specific setup
# Windows: Install VS 2022 + WebView2
# Linux: sudo apt install -y libwebkit2gtk-4.1-dev libgtk-3-dev
# macOS: xcode-select --install
```

### 5.2 Running Tests

```bash
# Engine tests
npm run test:engine

# Frontend tests
npm test

# Browser workflow tests
npm run test:ui

# Build verification
npm run build
npm run verify:sources
cargo check -p sesm-desktop --locked

# Full desktop build
npm run tauri build
```

### 5.3 Test Automation

See `scripts/run-acceptance-tests.sh` for automated test execution.

---

## 6. Evidence Collection

See `EVIDENCE-COLLECTION.md` for detailed evidence collection procedures.

### 6.1 Required Evidence per Platform

1. **Installation Evidence**
   - Package hash (SHA-256)
   - Installation timestamp
   - Installation method (MSIX, AppImage, DMG)
   - Version verification

2. **Runtime Evidence**
   - Application launch screenshot
   - Version info display
   - Platform identification

3. **Workflow Evidence**
   - Screenshot of file import
   - Screenshot of metadata editing
   - Screenshot of validation results
   - Screenshot of approval
   - Screenshot of export receipt
   - Export destination contents
   - Output file hashes

4. **Preservation Evidence**
   - Source file hash (before)
   - Source file hash (after) - must match
   - Output file hash
   - Export receipt hash
   - Raster comparison (before/after PNGs)

5. **Recovery Evidence**
   - Crash simulation results
   - Partial export cleanup verification
   - Discard prompt confirmation

---

## 7. Acceptance Criteria

### 7.1 Platform-Specific Criteria

Each platform must demonstrate:

1. **Installation**
   - [ ] Package installs without errors
   - [ ] Application launches successfully
   - [ ] Version displays correctly (0.1.0)
   - [ ] Window title shows "SESM Desktop · Aptlantis-Factor"

2. **Core Workflow**
   - [ ] Import at least 3 SVG files (single and batch)
   - [ ] Edit metadata via both structured and JSON editors
   - [ ] Validate drafts with no errors
   - [ ] Approve all imported files
   - [ ] Export to new folder with receipt
   - [ ] Verify output files are valid SVGs with embedded SESM

3. **Safety Validation**
   - [ ] Reject SVG with `<script>` tag
   - [ ] Reject SVG with event handlers
   - [ ] Reject SVG with DTD
   - [ ] Reject SVG with external entities
   - [ ] Reject SVG with duplicate SESM blocks

4. **Preservation Validation**
   - [ ] Byte preservation outside SESM block
   - [ ] Line ending preservation (CRLF/LF)
   - [ ] BOM preservation
   - [ ] Arbitrary precision number preservation
   - [ ] Unknown field preservation

5. **Recovery**
   - [ ] Cancel export mid-process
   - [ ] Verify partial files are cleaned up
   - [ ] Close without saving (discard prompt)
   - [ ] Attempt export after source modification (error)

### 7.2 Cross-Platform Criteria

- [ ] All platforms produce identical output hashes for same input
- [ ] All platforms produce identical validation results for same input
- [ ] All platforms handle all test cases consistently
- [ ] No platform-specific regressions

---

## 8. Pass/Fail Criteria

### 8.1 Individual Test
- **PASS:** Expected result achieved, no errors
- **FAIL:** Expected result not achieved, or unexpected error
- **BLOCKED:** Test cannot be executed due to environment issue
- **SKIPPED:** Test not applicable to platform

### 8.2 Platform Acceptance
- **ACCEPT:** All critical tests PASS (functional, safety, preservation)
- **REJECT:** Any critical test FAILS
- **CONDITIONAL:** Non-critical tests FAIL but critical tests PASS

### 8.3 Release Acceptance
- **VERIFIED:** All platforms ACCEPT
- **PARTIAL:** Some platforms ACCEPT, others pending
- **REJECTED:** Any platform REJECTED

### 8.4 Critical Tests

The following tests are **critical** and must PASS for platform acceptance:

- FT-01 through FT-05 (Import)
- FT-11 through FT-14 (Editing)
- FT-21 through FT-25 (Validation)
- FT-31 through FT-39 (Approval/Export)
- ST-01 through ST-10 (Safety)
- PT-01 through PT-07 (Preservation)
- VT-01, VT-02 (Visual Preservation)
- RT-01, RT-02, RT-05 (Recovery)

All other tests are **non-critical** but should PASS for full verification.

---

## 9. Test Matrix

| Test ID | Windows | Linux | macOS | Critical |
|---------|---------|-------|-------|----------|
| FT-01 through FT-40 | ✓ | ✓ | ✓ | Varies |
| ST-01 through ST-10 | ✓ | ✓ | ✓ | Yes |
| PT-01 through PT-07 | ✓ | ✓ | ✓ | Yes |
| VT-01 through VT-04 | ✓ | ✓ | ✓ | Varies |
| RT-01 through RT-09 | ✓ | ✓ | ✓ | Varies |
| RG-01 through RG-08 | ✓ | ✓ | ✓ | Yes |
| CP-01 through CP-04 | ✓ | ✓ | ✓ | Yes |

---

## 10. Schedule and Resources

### 10.1 Estimated Time

| Activity | Estimated Time |
|----------|----------------|
| VM Setup (per platform) | 2-4 hours |
| Test Execution (per platform) | 4-6 hours |
| Evidence Collection | 1-2 hours |
| Evidence Review | 1-2 hours |
| **Total per platform** | **8-14 hours** |
| **All three platforms** | **24-42 hours** |

### 10.2 Required Resources

- Windows 10/11 VM or physical machine
- Ubuntu 22.04 LTS VM (VMware, VirtualBox, or QEMU/KVM)
- macOS 13+ VM (UTM for ARM, or physical Intel Mac)
- Test SVG files (provided in `tests/fixtures/`)
- Screenshot capture tool
- Hash verification tool (sha256sum, PowerShell Get-FileHash)
- Text comparison tool (diff)

---

## 11. Deliverables

1. **Test Results**
   - Per-platform test execution log
   - Pass/fail summary
   - Timestamps for each test

2. **Evidence Archive**
   - Screenshots (PNG format)
   - Export receipts (JSON)
   - Output files (SVG)
   - Hash files (SHA-256)
   - Log files

3. **Validation Report**
   - Platform-specific acceptance status
   - Cross-platform parity analysis
   - DRS gate completion status

4. **Updated Documentation**
   - `evidence/validation.md` (updated)
   - `evidence/local/` (new evidence)
   - Platform-specific acceptance documents

---

## 12. Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| VM performance issues | Medium | High | Use lightweight VMs, allocate sufficient resources |
| Platform-specific build issues | Medium | High | Test builds early, document platform requirements |
| Renderer differences across platforms | Low | Medium | Use resvg consistently, accept minor rendering differences |
| Test environment contamination | Low | Medium | Use fresh VMs for each test run |
| Evidence loss | Low | High | Backup evidence frequently, use version control |
| Time estimation inaccuracies | Medium | Low | Track progress, adjust schedule as needed |

---

## 13. Appendices

### Appendix A: Test Data

Test SVG files are provided in `tests/fixtures/`:
- `atlas-infographic.svg` - Complex structured SVG
- `pipeline-bars.svg` - Data visualization
- `pipeline-artwork.svg` - Vector artwork
- `factor-palette-board.svg` - Color palette
- `embedded-raster.svg` - SVG with embedded PNG

Additional test data can be generated using `scripts/generate-test-fixtures.mjs`.

### Appendix B: Related Documents

- `README.md` - User documentation
- `Project-Proposal.md` - Project definition
- `Roadmap.md` - Implementation phases
- `ARCHITECTURE.md` - Technical architecture
- `TRUST.md` - Security model
- `RECOVERY.md` - Recovery procedures
- `Validation-Checklist.md` - Release checklist
- `TESTING-VM-GUIDE.md` - VM setup guide
- `EVIDENCE-COLLECTION.md` - Evidence collection procedures

### Appendix C: Glossary

| Term | Definition |
|------|------------|
| SESM | Self-describing Embedded Standard Metadata |
| DRS | Delivery Readiness Standard |
| PPS | Project Proposal Standard |
| L1-L5 | Test levels (unit, integration, acceptance, etc.) |
| FT | Functional Test |
| ST | Safety Test |
| PT | Preservation Test |
| VT | Visual Test |
| RT | Recovery Test |
| CP | Cross-Platform Test |
| RG | Regression Test |

---

**Document Status:** Ready for execution  
**Next Review:** After platform testing  
**Owner:** SESM Desktop Team
