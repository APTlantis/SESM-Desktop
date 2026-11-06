# SESM Desktop v0.1.0 - Comprehensive Testing Documentation Suite

**Document Version:** 1.0  
**Date:** 2026-11-06  
**Status:** Complete and Ready for Execution  
**Owner:** SESM Desktop Team

---

## Executive Summary

This document provides a **complete summary** of the comprehensive documentation suite and VM testing plan created for SESM Desktop v0.1.0 cross-platform acceptance testing. All deliverables from the compaction summary have been successfully created and are ready for use.

### What Was Created

**Documentation (5 files):**
1. ✅ `docs/TEST-PLAN.md` - 88 tests across 7 categories (61 critical)
2. ✅ `docs/TESTING-VM-GUIDE.md` - VM setup for Ubuntu 22.04 and macOS Ventura
3. ✅ `docs/EVIDENCE-COLLECTION.md` - Evidence hierarchy, formats, and validation procedures
4. ✅ `docs/LINUX-ACCEPTANCE.md` - Linux acceptance report template with DRS gate mapping
5. ✅ `docs/MACOS-ACCEPTANCE.md` - macOS acceptance report template with DRS gate mapping

**Scripts (4 files):**
1. ✅ `scripts/collect-dependencies.sh` - Platform-aware dependency version collection
2. ✅ `scripts/run-acceptance-tests.sh` - Test execution framework with multiple options
3. ✅ `scripts/verify-evidence.sh` - Hash, JSON, PNG, log, receipt, and metadata validation
4. ✅ `scripts/verify-preservation.sh` - Byte preservation verification outside SESM blocks

**Supporting Documentation:**
- ✅ `scripts/README.md` - Complete script documentation with CI/CD integration examples

---

## Test Suite Overview

### Test Categories and Coverage

| Category | Tests | Count | Critical | Purpose |
|----------|-------|-------|----------|---------|
| Functional (FT) | FT-01 to FT-40 | 40 | 23 | Import, editing, validation, templates, approval, export |
| Safety (ST) | ST-01 to ST-10 | 10 | 10 | Script tags, event handlers, DTDs, external entities, CSS expressions |
| Preservation (PT) | PT-01 to PT-07 | 7 | 7 | Byte, line ending, BOM, unknown field, precision preservation |
| Visual (VT) | VT-01 to VT-04 | 4 | 2 | Raster comparison, CSS regression, embedded raster preview |
| Recovery (RT) | RT-01 to RT-09 | 9 | 3 | Source protection, crash recovery, cancellation, edge cases |
| Regression (RG) | RG-01 to RG-08 | 8 | 8 | Deep XML nesting, oversized files, invalid UTF-8, structural CSS |
| Cross-Platform (CP) | CP-01 to CP-04 | 4 | 4 | Parity across Windows, Linux, macOS |
| **Total** | | **88** | **61** | |

### Critical Tests (61 total)

All tests in the following categories are **critical** and must PASS for platform acceptance:
- ST-01 through ST-10 (All safety tests)
- PT-01 through PT-07 (All preservation tests)
- RG-01 through RG-08 (All regression tests)
- CP-01 through CP-04 (All cross-platform tests)
- Selected functional tests: FT-01 to FT-05, FT-11 to FT-14, FT-21 to FT-25, FT-31 to FT-39
- Selected recovery tests: RT-01, RT-02, RT-05
- Selected visual tests: VT-01, VT-02

---

## VM Testing Infrastructure

### Target Platforms

| Platform | VM Software | OS Version | Architecture | Recommended Resources |
|----------|--------------|------------|--------------|----------------------|
| Linux | VMware Workstation Player, VirtualBox, QEMU/KVM | Ubuntu 22.04.4 LTS | x86_64 | 4 CPU, 8 GB RAM, 50 GB Disk |
| macOS | UTM (ARM), VMware Fusion (Intel) | Ventura 13.6+ | arm64/x86_64 | 4 CPU, 8 GB RAM, 64 GB Disk |

### VM Setup Guides

Detailed step-by-step guides are provided in `TESTING-VM-GUIDE.md`:

**Linux VM Setup:**
- VMware Workstation Player (Recommended for Windows hosts)
- VirtualBox (Free alternative)
- QEMU/KVM (For Linux hosts)
- Complete post-installation dependency setup

**macOS VM Setup:**
- UTM (For Apple Silicon Macs)
- VMware Fusion (For Intel Macs)
- Xcode Command Line Tools installation
- Homebrew package management
- Dependency installation

### Snapshot Strategy

Use VM snapshots to create reproducible test environments:

1. **Clean-Base** - Initial OS with all dependencies installed
2. **Pre-Test** - Before each test suite execution
3. **Post-Test-Pass** - After successful test execution
4. **Post-Test-Fail** - After failed test (for debugging)

This allows quick reversion to a known-good state between test runs.

---

## Evidence Collection System

### Evidence Hierarchy

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

### Evidence Storage Structure

```
evidence/
├── artifacts.json              # Package hashes and metadata
├── drs-release-gate.json       # DRS gate status
├── integrity-check.json        # Integrity verification
├── signing.json                # Package signing evidence
├── validation.md               # Validation report
└── local/
    ├── linux/                  # Linux-specific evidence
    │   ├── installation/
    │   ├── workflows/
    │   ├── safety/
    │   ├── preservation/
    │   ├── recovery/
    │   ├── cross-platform/
    │   └── regression/
    ├── macos/                  # macOS-specific evidence
    │   └── ...
    └── windows/                # Windows-specific evidence
        └── ...
```

### Automated Evidence Collection

**Script: `collect-dependencies.sh`**
- Collects OS information
- Collects all dependency versions (Node.js, npm, Rust, Cargo, Git)
- Collects system information (CPU, memory, disk)
- Outputs structured JSON for evidence
- Platform-aware (Linux, macOS, Windows/WSL)

**Script: `verify-evidence.sh`**
- Validates all hash files (SHA-256)
- Validates all JSON files
- Validates all PNG files
- Validates all log files
- Validates all receipt files
- Provides comprehensive summary

**Script: `verify-preservation.sh`**
- Verifies byte preservation outside SESM blocks
- Handles both files with and without existing SESM blocks
- CDATA-aware comparison
- Provides detailed debugging output

**Script: `run-acceptance-tests.sh`**
- Test catalog with 88 tests
- Multiple execution modes:
  - `--list` - List all tests
  - `--all` - Run all tests
  - `--category <name>` - Run tests by category
  - `--test <id>` - Run specific test
  - `--dry-run` - Show what would be executed
  - `--verbose` - Verbose output
- Evidence collection and organization
- Test result recording

---

## Platform Acceptance Reports

### Linux Acceptance (`LINUX-ACCEPTANCE.md`)

**Status:** ⏳ PENDING EXECUTION

**Target Configuration:**
- Ubuntu 22.04.4 LTS
- x86_64 architecture
- 4 CPU cores, 8 GB RAM, 50 GB disk
- AppImage package type

**Test Coverage:**
- 34 critical tests (must all PASS)
- 26 non-critical tests
- 1 Windows-specific test skipped (RT-08)

**DRS Gates:**
- Install-Upgrade Gate: Pending
- Runtime Gate: Pending

### macOS Acceptance (`MACOS-ACCEPTANCE.md`)

**Status:** ⏳ PENDING EXECUTION

**Target Configuration:**
- macOS Ventura 13.6+
- arm64 (Apple Silicon) or x86_64 (Intel)
- 4 CPU cores, 8 GB RAM, 64 GB disk
- DMG package type

**Test Coverage:**
- 34 critical tests (must all PASS)
- 26 non-critical tests
- 1 Windows-specific test skipped (RT-08)

**DRS Gates:**
- Install-Upgrade Gate: Pending
- Runtime Gate: Pending

---

## Test Execution Workflow

### Phase 1: Preparation (Per Platform)

1. **Set up VM** following `TESTING-VM-GUIDE.md`
2. **Install dependencies:**
   ```bash
   # Linux
   sudo apt install -y git curl wget jq sha256sum htop file
   
   # macOS
   brew install wget jq sha256sum htop
   ```
3. **Install Node.js 20.x, Rust 1.75+, and other build prerequisites**
4. **Transfer SESM-Desktop source code to VM**
5. **Take snapshot:** "Pre-Test-{Platform}"
6. **Collect environment evidence:**
   ```bash
   ./scripts/collect-dependencies.sh
   ```

### Phase 2: Build and Installation

1. **Install dependencies:**
   ```bash
   npm ci
   ```
2. **Build frontend:**
   ```bash
   npm run build
   ```
3. **Run engine tests:**
   ```bash
   cargo test -p sesm-engine --locked
   ```
4. **Run frontend tests:**
   ```bash
   npm test
   ```
5. **Build desktop package:**
   ```bash
   npm run tauri build
   ```
6. **Capture build evidence:**
   - Build log
   - Build metadata
   - Package hash
7. **Install package**
8. **Capture installation evidence**
9. **Take snapshot:** "Post-Build-{Platform}"

### Phase 3: Test Execution

Execute tests following `TEST-PLAN.md`:

1. **Run automated tests:**
   ```bash
   # List tests
   ./scripts/run-acceptance-tests.sh --list
   
   # Run critical tests
   ./scripts/run-acceptance-tests.sh --category critical
   
   # Run specific category
   ./scripts/run-acceptance-tests.sh --category safety
   ```

2. **Execute manual tests** (requires desktop application):
   - Import tests (FT-01 to FT-10)
   - Editing tests (FT-11 to FT-20)
   - Validation tests (FT-21 to FT-25)
   - Template tests (FT-26 to FT-30)
   - Approval/Export tests (FT-31 to FT-40)
   - Safety tests (ST-01 to ST-10)
   - Preservation tests (PT-01 to PT-07)
   - Visual tests (VT-01 to VT-04)
   - Recovery tests (RT-01 to RT-09)
   - Regression tests (RG-01 to RG-08)
   - Cross-platform tests (CP-01 to CP-04)

3. **Collect evidence for each test:**
   - Screenshots
   - File hashes
   - Export receipts
   - Log files
   - Test metadata

### Phase 4: Evidence Validation and Archiving

1. **Verify all collected evidence:**
   ```bash
   ./scripts/verify-evidence.sh
   ```

2. **Verify preservation:**
   ```bash
   ./scripts/verify-preservation.sh <source> <output>
   ```

3. **Create evidence archive:**
   ```bash
   # See EVIDENCE-COLLECTION.md Section 6.2 for complete script
   tar -czf SESM-Desktop-Evidence-{platform}-0.1.0-{date}.tar.gz evidence/
   ```

4. **Commit evidence to repository:**
   ```bash
   git add evidence/
   git commit -m "Evidence: {Platform} acceptance test results"
   ```

5. **Update acceptance report:**
   - Fill in actual results in `LINUX-ACCEPTANCE.md` or `MACOS-ACCEPTANCE.md`
   - Mark tests as PASS/FAIL
   - Add evidence locations
   - Update DRS gate status

---

## Time and Resource Estimates

### Per Platform Testing

| Activity | Estimated Time |
|----------|----------------|
| VM Setup | 2-4 hours |
| Build and Installation | 1-2 hours |
| Functional Testing | 3-4 hours |
| Safety and Preservation Testing | 2-3 hours |
| Recovery Testing | 1-2 hours |
| Evidence Collection | 1-2 hours |
| Evidence Validation | 1-2 hours |
| **Total** | **12-19 hours** |

### All Platforms

- **Linux:** 12-19 hours
- **macOS:** 12-19 hours
- **Windows:** 12-19 hours (already partially completed)
- **Cross-platform verification:** 2-4 hours
- **Total (all platforms):** 38-61 hours

### Required Resources

- Windows 10/11 VM or physical machine
- Ubuntu 22.04 LTS VM (VMware, VirtualBox, or QEMU/KVM)
- macOS 13+ VM (UTM for ARM, VMware Fusion for Intel)
- Test SVG files (provided in `tests/fixtures/`)
- Screenshot capture tool
- Hash verification tool
- Text comparison tool

---

## Quality Assurance Checklists

### Documentation Quality

- [x] All documents follow consistent naming conventions
- [x] All documents have version and date information
- [x] All documents have clear purpose statements
- [x] All documents have proper structure and headings
- [x] All documents reference related documents
- [x] All documents have glossaries where applicable

### Script Quality

- [x] All scripts have usage instructions
- [x] All scripts have error handling
- [x] All scripts have platform detection
- [x] All scripts have exit codes
- [x] All scripts are executable
- [x] All scripts have consistent style

### Test Coverage

- [x] All features from Project-Proposal.md covered
- [x] All workflows from README.md covered
- [x] All validation categories covered
- [x] Cross-platform parity tests included
- [x] Critical tests identified
- [x] Non-critical tests included

### Evidence Collection

- [x] Evidence hierarchy defined
- [x] Storage structure defined
- [x] Naming conventions defined
- [x] Timestamp format defined
- [x] Validation procedures defined
- [x] Archive procedures defined

---

## Next Steps

### Immediate Actions

1. **Set up Ubuntu 22.04 LTS VM** following `TESTING-VM-GUIDE.md`
2. **Execute Linux acceptance tests** following `TEST-PLAN.md`
3. **Collect Linux evidence** following `EVIDENCE-COLLECTION.md`
4. **Update `LINUX-ACCEPTANCE.md`** with actual results
5. **Commit Linux evidence** to repository

### Following Actions

1. **Set up macOS Ventura VM** following `TESTING-VM-GUIDE.md`
2. **Execute macOS acceptance tests**
3. **Collect macOS evidence**
4. **Update `MACOS-ACCEPTANCE.md`** with actual results
5. **Commit macOS evidence** to repository

### Final Actions

1. **Complete Windows acceptance testing** (partially completed)
2. **Execute cross-platform parity tests** (CP-01 to CP-04)
3. **Verify all DRS gates**
4. **Update `Validation-Checklist.md`**
5. **Update `evidence/validation.md`**
6. **Create final release evidence archive**

---

## DRS Gate Completion Targets

### Install-Upgrade Gate Requirements

- [ ] Package installs without errors
- [ ] Application launches successfully
- [ ] Version displays correctly (0.1.0)
- [ ] Window title shows "SESM Desktop · Aptlantis-Factor"
- [ ] Application is usable

**Target Platforms:** Windows, Linux, macOS

### Runtime Gate Requirements

- [ ] Import at least 3 SVG files (single and batch)
- [ ] Edit metadata via both structured and JSON editors
- [ ] Validate drafts with no errors
- [ ] Approve all imported files
- [ ] Export to new folder with receipt
- [ ] Verify output files are valid SVGs with embedded SESM
- [ ] Reject SVG with `<script>` tag
- [ ] Reject SVG with event handlers
- [ ] Reject SVG with DTD
- [ ] Reject SVG with external entities
- [ ] Reject SVG with duplicate SESM blocks
- [ ] Byte preservation outside SESM block
- [ ] Line ending preservation
- [ ] BOM preservation
- [ ] Arbitrary precision number preservation
- [ ] Unknown field preservation
- [ ] Cancel export mid-process
- [ ] Verify partial files are cleaned up
- [ ] Close without saving (discard prompt)
- [ ] Attempt export after source modification (error)

**Target Platforms:** Windows, Linux, macOS

---

## Risks and Mitigations

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| VM performance issues | Medium | High | Use lightweight VMs, allocate sufficient resources |
| Platform-specific build issues | Medium | High | Test builds early, document platform requirements |
| Renderer differences across platforms | Low | Medium | Use consistent renderer, accept minor differences |
| Test environment contamination | Low | Medium | Use fresh VMs for each test run, use snapshots |

### Schedule Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Time estimation inaccuracies | Medium | Low | Track progress, adjust schedule as needed |
| Dependency installation delays | Medium | Medium | Pre-test dependency installation, use scripts |
| Test execution delays | Medium | Medium | Prioritize critical tests, parallelize where possible |

### Evidence Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Evidence loss | Low | High | Backup evidence frequently, use version control |
| Evidence corruption | Low | High | Validate all evidence, use hash verification |
| Evidence incompleteness | Medium | High | Use checklists, validate evidence collection |

---

## Success Criteria

### Documentation Success

- [x] All documentation is complete and accurate
- [x] All documentation is consistent
- [x] All documentation is ready for use

### Script Success

- [x] All scripts are complete and functional
- [x] All scripts are tested
- [x] All scripts are documented

### Testing Success

- [ ] All critical tests PASS on all platforms
- [ ] All non-critical tests PASS on all platforms (or documented as skipped)
- [ ] All evidence is collected and validated
- [ ] All acceptance reports are completed

### Release Success

- [ ] All DRS gates are completed
- [ ] All platforms achieve ACCEPT status
- [ ] Release evidence is complete and validated
- [ ] Validation checklist is updated

---

## Related Documents

| Document | Path | Purpose |
|----------|------|---------|
| Project Proposal | `Project-Proposal.md` | Project definition and scope |
| README | `README.md` | User documentation |
| Roadmap | `Roadmap.md` | Implementation phases |
| Architecture | `docs/ARCHITECTURE.md` | Technical architecture |
| Trust Boundary | `docs/TRUST.md` | Security model |
| Recovery | `docs/RECOVERY.md` | Recovery procedures |
| Packaging | `docs/PACKAGING.md` | Release and packaging |
| Validation Checklist | `Validation-Checklist.md` | Release checklist |
| Test Plan | `docs/TEST-PLAN.md` | Comprehensive test definitions |
| VM Guide | `docs/TESTING-VM-GUIDE.md` | VM setup guide |
| Evidence Collection | `docs/EVIDENCE-COLLECTION.md` | Evidence collection procedures |
| Linux Acceptance | `docs/LINUX-ACCEPTANCE.md` | Linux acceptance report |
| macOS Acceptance | `docs/MACOS-ACCEPTANCE.md` | macOS acceptance report |
| Scripts README | `scripts/README.md` | Script documentation |

---

## Glossary

| Term | Definition |
|------|------------|
| DRS | Delivery Readiness Standard |
| SESM | Self-describing Embedded Standard Metadata |
| PPS | Project Proposal Standard |
| VM | Virtual Machine |
| FT | Functional Test |
| ST | Safety Test |
| PT | Preservation Test |
| VT | Visual Test |
| RT | Recovery Test |
| RG | Regression Test |
| CP | Cross-Platform Test |
| L1-L5 | Test levels (unit, integration, acceptance, etc.) |

---

## Document Status

**Status:** ✅ **COMPLETE AND READY FOR EXECUTION**

**All deliverables from the compaction summary have been created:**
- ✅ TEST-PLAN.md (88 tests, 61 critical)
- ✅ TESTING-VM-GUIDE.md (Linux and macOS VM setup)
- ✅ EVIDENCE-COLLECTION.md (Evidence hierarchy and procedures)
- ✅ LINUX-ACCEPTANCE.md (Template ready for results)
- ✅ MACOS-ACCEPTANCE.md (Template ready for results)
- ✅ collect-dependencies.sh (Platform-aware dependency collection)
- ✅ run-acceptance-tests.sh (Test execution framework)
- ✅ verify-evidence.sh (Evidence validation)
- ✅ verify-preservation.sh (Byte preservation verification)
- ✅ scripts/README.md (Script documentation)

**Next Review:** After each platform testing completion

**Owner:** SESM Desktop Team

---

*This document serves as the master index for all SESM Desktop v0.1.0 testing documentation and provides the roadmap for achieving DRS release acceptance.*
