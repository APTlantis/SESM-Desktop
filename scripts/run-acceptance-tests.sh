#!/bin/bash
# run-acceptance-tests.sh
# Main script for running SESM Desktop v0.1.0 acceptance tests
# Part of DRS Phase 4 Release Readiness

set -euo pipefail

# Configuration
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
EVIDENCE_DIR="$PROJECT_ROOT/evidence/local/${PLATFORM}"
TEST_PLAN="$PROJECT_ROOT/docs/TEST-PLAN.md"
LOG_DIR="$EVIDENCE_DIR/logs"
RESULTS_DIR="$EVIDENCE_DIR/results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create directories
mkdir -p "$EVIDENCE_DIR" "$LOG_DIR" "$RESULTS_DIR"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
print_banner() {
    echo ""
    echo "=========================================================="
    echo "  SESM Desktop v0.1.0 - Acceptance Testing"
    echo "  Platform: $PLATFORM"
    echo "  Timestamp: $TIMESTAMP"
    echo "=========================================================="
    echo ""
}

# Usage
print_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_CATEGORY]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -l, --list          List all available tests"
    echo "  -c, --category      Run tests by category (functional, safety, preservation, etc.)"
    echo "  -t, --test          Run specific test by ID"
    echo "  -a, --all           Run all tests"
    echo "  -d, --dry-run       Show what would be run without executing"
    echo "  -v, --verbose       Verbose output"
    echo ""
    echo "Test Categories:"
    echo "  functional     - Functional tests (FT-01 to FT-40)"
    echo "  safety        - Safety tests (ST-01 to ST-10)"
    echo "  preservation  - Preservation tests (PT-01 to PT-07)"
    echo "  visual        - Visual tests (VT-01 to VT-04)"
    echo "  recovery      - Recovery tests (RT-01 to RT-09)"
    echo "  regression    - Regression tests (RG-01 to RG-08)"
    echo "  cross-platform - Cross-platform tests (CP-01 to CP-04)"
    echo "  critical      - Critical tests only"
    echo ""
    echo "Examples:"
    echo "  $0 --all                      # Run all tests"
    echo "  $0 --category functional       # Run functional tests"
    echo "  $0 --test FT-01                # Run specific test"
    echo "  $0 --category critical         # Run critical tests only"
}

# Define test categories and their tests
declare -A TEST_CATEGORIES=(
    [functional]="FT-01 FT-02 FT-03 FT-04 FT-05 FT-06 FT-07 FT-08 FT-09 FT-10 FT-11 FT-12 FT-13 FT-14 FT-15 FT-16 FT-17 FT-18 FT-19 FT-20 FT-21 FT-22 FT-23 FT-24 FT-25 FT-26 FT-27 FT-28 FT-29 FT-30 FT-31 FT-32 FT-33 FT-34 FT-35 FT-36 FT-37 FT-38 FT-39 FT-40"
    [safety]="ST-01 ST-02 ST-03 ST-04 ST-05 ST-06 ST-07 ST-08 ST-09 ST-10"
    [preservation]="PT-01 PT-02 PT-03 PT-04 PT-05 PT-06 PT-07"
    [visual]="VT-01 VT-02 VT-03 VT-04"
    [recovery]="RT-01 RT-02 RT-03 RT-04 RT-05 RT-06 RT-07 RT-08 RT-09"
    [regression]="RG-01 RG-02 RG-03 RG-04 RG-05 RG-06 RG-07 RG-08"
    [cross-platform]="CP-01 CP-02 CP-03 CP-04"
)

# Define critical tests
CRITICAL_TESTS=(
    "FT-01" "FT-02" "FT-03" "FT-04" "FT-05"   # Import
    "FT-11" "FT-12" "FT-13" "FT-14"           # Editing
    "FT-21" "FT-22" "FT-23" "FT-24" "FT-25"   # Validation
    "FT-31" "FT-32" "FT-33"                   # Approval/Export (partial)
    "FT-35" "FT-36" "FT-38"                   # Approval/Export (partial)
    "ST-01" "ST-02" "ST-03" "ST-04" "ST-05"   # Safety
    "ST-06" "ST-07" "ST-08" "ST-09" "ST-10"   # Safety
    "PT-01" "PT-02" "PT-03" "PT-04" "PT-05"   # Preservation
    "PT-06" "PT-07"                           # Preservation
    "VT-01" "VT-02"                           # Visual
    "RT-01" "RT-02" "RT-05"                   # Recovery
)

# Test descriptions
declare -A TEST_DESCRIPTIONS=(
    # Functional Tests
    [FT-01]="Single SVG Import - Open one SVG file via native picker"
    [FT-02]="Batch SVG Import - Open multiple SVG files"
    [FT-03]="SVG with Existing SESM - Open SVG with valid SESM 0.3.0 block"
    [FT-04]="SVG with SESM 0.2.0 - Open SVG with SESM 0.2.0 block"
    [FT-05]="SVG without SESM - Open SVG without metadata block"
    [FT-06]="Large SVG (4.9 MiB) - Open SVG near max size limit"
    [FT-07]="SVG at Max Size - Open SVG at exact limit"
    [FT-08]="SVG over Max Size - Attempt to open SVG > 5 MiB"
    [FT-09]="UTF-8 with BOM - Open SVG with UTF-8 BOM"
    [FT-10]="UTF-8 with CRLF - Open SVG with CRLF line endings"
    [FT-11]="Structured Field Edit - Edit asset/title field via form"
    [FT-12]="JSON Field Edit - Edit raw JSON directly"
    [FT-13]="Arbitrary Precision - Edit field with large integer"
    [FT-14]="Decimal Precision - Edit field with high-precision decimal"
    [FT-15]="Add New Field - Add custom field not in schema"
    [FT-16]="Remove Field - Delete a field via form"
    [FT-17]="Nested Object Edit - Edit nested object path"
    [FT-18]="Array Edit - Edit array field"
    [FT-19]="Invalid JSON Input - Enter malformed JSON"
    [FT-20]="Duplicate Key Input - Enter JSON with duplicate keys"
    [FT-21]="Valid Metadata - Validate correct SESM 0.3.0 JSON"
    [FT-22]="Schema Error - Validate invalid SESM schema"
    [FT-23]="Warning Only - Validate with warnings"
    [FT-24]="Safety Error - Validate with safety error"
    [FT-25]="Privacy Warning - Validate with privacy warning"
    [FT-26]="Save Template - Save current metadata as template"
    [FT-27]="Apply Template (No Conflicts) - Apply template with no overlapping fields"
    [FT-28]="Apply Template (With Conflicts) - Apply template with overlapping fields"
    [FT-29]="Apply Template (Selective Overwrite) - Apply with selected overwrite"
    [FT-30]="Delete Template - Delete a saved template"
    [FT-31]="Approve Single File - Approve one valid file"
    [FT-32]="Approve with Warnings - Approve file with warnings, acknowledged"
    [FT-33]="Approve with Errors - Attempt to approve file with errors"
    [FT-34]="Approve Changed Draft - Change draft after approval, re-approve"
    [FT-35]="Export Single File - Export one approved file"
    [FT-36]="Export Multiple Files - Export multiple approved files"
    [FT-37]="Export with Warnings - Export file with acknowledged warnings"
    [FT-38]="Export No Approved Files - Attempt export with no approved files"
    [FT-39]="Export to Existing Folder - Attempt export to existing destination"
    [FT-40]="Cancel Export - Start export, then cancel"
    # Safety Tests
    [ST-01]="SVG with Script Tag - Open SVG containing script element"
    [ST-02]="SVG with Event Handler - Open SVG with onload attribute"
    [ST-03]="SVG with ForeignObject - Open SVG with foreignObject"
    [ST-04]="SVG with DTD - Open SVG with DOCTYPE"
    [ST-05]="SVG with External Entity - Open SVG with external entity reference"
    [ST-06]="SVG with JavaScript URL - Open SVG with href=javascript:..."
    [ST-07]="SVG with CSS Expression - Open SVG with CSS expression()"
    [ST-08]="SVG with Nested SVG - Open SVG with nested svg in image href"
    [ST-09]="Multiple SESM Blocks - Open SVG with duplicate SESM metadata blocks"
    [ST-10]="SESM with Child Elements - Open SVG with SESM metadata containing XML children"
    # Preservation Tests
    [PT-01]="Byte Preservation - Edit metadata, compare bytes outside SESM range"
    [PT-02]="Line Ending Preservation - Edit metadata in file with CRLF"
    [PT-03]="BOM Preservation - Edit metadata in file with BOM"
    [PT-04]="Unknown Field Preservation - Add/remove fields, keep unknown field"
    [PT-05]="Arbitrary Precision Preservation - Edit other fields, keep high-precision number"
    [PT-06]="CDATA Delimiter Preservation - Metadata containing ]]>"
    [PT-07]="Namespaced SVG - Edit metadata in namespaced SVG"
    # Visual Tests
    [VT-01]="Raster Comparison - Edit metadata, compare before/after previews"
    [VT-02]="CSS First-Child Regression - Edit SVG with :first-child selector"
    [VT-03]="Embedded Raster Preview - Open SVG with embedded PNG"
    [VT-04]="Unsupported Embedded Raster - Open SVG with embedded SVG in data URL"
    # Recovery Tests
    [RT-01]="Source Changed After Import - Modify source file after import, attempt export"
    [RT-02]="Application Crash During Export - Kill app during export"
    [RT-03]="Disk Full During Export - Fill disk during export"
    [RT-04]="Permission Denied During Export - Export to read-only location"
    [RT-05]="Close Without Saving - Edit draft, attempt to close"
    [RT-06]="Reopen After Crash - Crash app with open files, reopen"
    [RT-07]="Non-Unicode Filename - Attempt to open file with non-Unicode name"
    [RT-08]="Reserved Filename (Windows) - Attempt to export file named CON.svg"
    [RT-09]="Case-Insensitive Collision - Export files with case-only name differences"
    # Regression Tests
    [RG-01]="Deep XML Nesting - XML depth > 128"
    [RG-02]="Oversized Metadata - Metadata > 64 KiB"
    [RG-03]="Oversized SVG - SVG > 5 MiB"
    [RG-04]="Oversized Preview - SVG renders > 16 megapixels"
    [RG-05]="Invalid UTF-8 - SVG with invalid UTF-8"
    [RG-06]="Non-SVG Root - XML with non-svg root"
    [RG-07]="Multiple SESM Blocks - SVG with duplicate SESM"
    [RG-08]="Structural CSS Change - Metadata insertion affects CSS"
    # Cross-Platform Tests
    [CP-01]="Same SVG on All Platforms - Open same SVG file on all platforms"
    [CP-02]="Same Template on All Platforms - Apply same template on all platforms"
    [CP-03]="Export Hash Consistency - Export same SVG on all platforms"
    [CP-04]="Preview Consistency - Generate preview on all platforms"
)

# Main execution
main() {
    print_banner
    
    # Parse arguments
    local run_all=false
    local run_category=""
    local run_test=""
    local dry_run=false
    local verbose=false
    local list_tests=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_usage
                exit 0
                ;;
            -l|--list)
                list_tests=true
                shift
                ;;
            -a|--all)
                run_all=true
                shift
                ;;
            -c|--category)
                if [[ -n "${2:-}" ]]; then
                    run_category="$2"
                    shift 2
                else
                    log_error "Category name required after --category"
                    exit 1
                fi
                ;;
            -t|--test)
                if [[ -n "${2:-}" ]]; then
                    run_test="$2"
                    shift 2
                else
                    log_error "Test ID required after --test"
                    exit 1
                fi
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # List tests if requested
    if $list_tests; then
        list_all_tests
        exit 0
    fi
    
    # Determine which tests to run
    local tests_to_run=()
    
    if $run_all; then
        # Add all tests
        for category in "${!TEST_CATEGORIES[@]}"; do
            for test in ${TEST_CATEGORIES[$category]}; do
                tests_to_run+=("$test")
            done
        done
    elif [[ -n "$run_category" ]]; then
        if [[ -n "${TEST_CATEGORIES[$run_category]:-}" ]]; then
            for test in ${TEST_CATEGORIES[$run_category]}; do
                tests_to_run+=("$test")
            done
        else
            log_error "Unknown category: $run_category"
            print_usage
            exit 1
        fi
    elif [[ -n "$run_test" ]]; then
        tests_to_run+=("$run_test")
    else
        # Default: run critical tests
        tests_to_run=("${CRITICAL_TESTS[@]}")
    fi
    
    # Run tests
    local total=0
    local passed=0
    local failed=0
    local skipped=0
    local blocked=0
    
    log_info "Tests to run: ${#tests_to_run[@]}"
    
    if $dry_run; then
        log_info "Dry run - showing tests that would be executed:"
        for test in "${tests_to_run[@]}"; do
            echo "  - $test: ${TEST_DESCRIPTIONS[$test]}"
        done
        exit 0
    fi
    
    # Run each test
    for test in "${tests_to_run[@]}"; do
        run_test "$test"
        
        # Update counters based on result
        # (This would be implemented in run_test function)
    done
    
    # Print summary
    print_summary
}

# List all tests
list_all_tests() {
    echo ""
    echo "All Available Tests:"
    echo "=========================================================="
    echo ""
    
    for category in "${!TEST_CATEGORIES[@]}"; do
        echo "[$category]"
        for test in ${TEST_CATEGORIES[$category]}; do
            local marker=""
            if [[ " ${CRITICAL_TESTS[@]} " =~ " $test " ]]; then
                marker=" *"
            fi
            echo "  $test$marker - ${TEST_DESCRIPTIONS[$test]}"
        done
        echo ""
    done
    
    echo "(* = Critical test - must PASS for acceptance)"
}

# Run a single test
run_test() {
    local test_id="$1"
    local description="${TEST_DESCRIPTIONS[$test_id]}"
    
    echo ""
    echo "----------------------------------------------------------"
    echo "Running: $test_id"
    echo "Description: $description"
    echo "----------------------------------------------------------"
    
    # Determine test category
    local category=""
    for cat in "${!TEST_CATEGORIES[@]}"; do
        if [[ " ${TEST_CATEGORIES[$cat]} " =~ " $test_id " ]]; then
            category="$cat"
            break
        fi
    done
    
    # Create test directory
    local test_dir="$EVIDENCE_DIR/${category}/${test_id}"
    mkdir -p "$test_dir"
    
    # Log file
    local log_file="$test_dir/${test_id}-${TIMESTAMP}.log"
    
    # Check if test is platform-specific
    if [[ "$test_id" == "RT-08" && "$PLATFORM" != "windows" ]]; then
        # Windows-specific test
        log_warning "Test $test_id is Windows-specific, skipping on $PLATFORM"
        record_result "$test_id" "SKIPPED" "Platform-specific (Windows only)"
        return
    fi
    
    # Execute test based on category
    case "$category" in
        functional)
            run_functional_test "$test_id" "$test_dir" "$log_file"
            ;;
        safety)
            run_safety_test "$test_id" "$test_dir" "$log_file"
            ;;
        preservation)
            run_preservation_test "$test_id" "$test_dir" "$log_file"
            ;;
        visual)
            run_visual_test "$test_id" "$test_dir" "$log_file"
            ;;
        recovery)
            run_recovery_test "$test_id" "$test_dir" "$log_file"
            ;;
        regression)
            run_regression_test "$test_id" "$test_dir" "$log_file"
            ;;
        cross-platform)
            run_cross_platform_test "$test_id" "$test_dir" "$log_file"
            ;;
        *)
            log_error "Unknown test category: $category"
            record_result "$test_id" "FAILED" "Unknown category"
            ;;
    esac
}

# Test runners (stubs - to be implemented or called via Tauri IPC)
run_functional_test() {
    local test_id="$1"
    local test_dir="$2"
    local log_file="$3"
    
    log_info "Running functional test: $test_id"
    
    # These tests require the desktop application to be running
    # For automated testing, we would need to:
    # 1. Launch the application
    # 2. Send IPC commands
    # 3. Capture results
    
    # For now, we'll simulate or provide instructions
    case "$test_id" in
        FT-01|FT-02|FT-03|FT-04|FT-05)
            # Import tests
            log_info "Test $test_id requires manual execution or Tauri automation"
            record_result "$test_id" "BLOCKED" "Requires desktop application - see TESTING-VM-GUIDE.md"
            ;;
        *)
            log_info "Test $test_id requires manual execution"
            record_result "$test_id" "BLOCKED" "Requires desktop application"
            ;;
    esac
}

run_safety_test() {
    local test_id="$1"
    local test_dir="$2"
    local log_file="$3"
    
    log_info "Running safety test: $test_id"
    
    # Safety tests can be run via the Rust engine directly
    case "$test_id" in
        ST-01|ST-02|ST-03|ST-04|ST-05|ST-06|ST-07|ST-08|ST-09|ST-10)
            # Create test SVG files
            local test_svg="$test_dir/test-input.svg"
            create_test_svg "$test_id" "$test_svg"
            
            # Run via cargo
            log_info "Running engine test for $test_id"
            
            # The Rust engine can analyze SVGs and report findings
            # This would be integrated with the actual engine
            record_result "$test_id" "BLOCKED" "Requires Rust engine integration - see crates/sesm-engine"
            ;;
        *)
            record_result "$test_id" "BLOCKED" "Test not recognized"
            ;;
    esac
}

run_preservation_test() {
    local test_id="$1"
    local test_dir="$2"
    local log_file="$3"
    
    log_info "Running preservation test: $test_id"
    
    # Preservation tests can be automated with the Rust engine
    case "$test_id" in
        PT-01|PT-02|PT-03|PT-04|PT-05|PT-06|PT-07)
            # Use the verify-preservation script
            log_info "Running preservation verification for $test_id"
            record_result "$test_id" "BLOCKED" "Use scripts/verify-preservation.sh - see EVIDENCE-COLLECTION.md"
            ;;
        *)
            record_result "$test_id" "BLOCKED" "Test not recognized"
            ;;
    esac
}

run_visual_test() {
    local test_id="$1"
    local test_dir="$2"
    local log_file="$3"
    
    log_info "Running visual test: $test_id"
    
    # Visual tests require rendering
    case "$test_id" in
        VT-01|VT-02|VT-03|VT-04)
            log_info "Visual test $test_id requires raster rendering"
            record_result "$test_id" "BLOCKED" "Requires raster comparison - see TEST-PLAN.md section 3.4"
            ;;
        *)
            record_result "$test_id" "BLOCKED" "Test not recognized"
            ;;
    esac
}

run_recovery_test() {
    local test_id="$1"
    local test_dir="$2"
    local log_file="$3"
    
    log_info "Running recovery test: $test_id"
    
    case "$test_id" in
        RT-01|RT-02|RT-03|RT-04|RT-05|RT-06|RT-07|RT-08|RT-09)
            log_info "Recovery test $test_id requires application interaction"
            record_result "$test_id" "BLOCKED" "Requires application interaction - see TEST-PLAN.md section 3.5"
            ;;
        *)
            record_result "$test_id" "BLOCKED" "Test not recognized"
            ;;
    esac
}

run_regression_test() {
    local test_id="$1"
    local test_dir="$2"
    local log_file="$3"
    
    log_info "Running regression test: $test_id"
    
    # Regression tests can be automated
    case "$test_id" in
        RG-01)
            # Deep XML nesting
            log_info "Test RG-01: Creating deeply nested SVG..."
            create_deep_xml "$test_dir/test-rg-01.svg" 130
            record_result "$test_id" "BLOCKED" "Test file created, requires engine validation"
            ;;
        RG-02)
            # Oversized metadata
            log_info "Test RG-02: Creating SVG with oversized metadata..."
            create_oversized_metadata "$test_dir/test-rg-02.svg"
            record_result "$test_id" "BLOCKED" "Test file created, requires engine validation"
            ;;
        RG-03)
            # Oversized SVG
            log_info "Test RG-03: Creating SVG at max size..."
            create_oversized_svg "$test_dir/test-rg-03.svg"
            record_result "$test_id" "BLOCKED" "Test file created, requires engine validation"
            ;;
        *)
            record_result "$test_id" "BLOCKED" "Regression test not yet automated"
            ;;
    esac
}

run_cross_platform_test() {
    local test_id="$1"
    local test_dir="$2"
    local log_file="$3"
    
    log_info "Running cross-platform test: $test_id"
    
    case "$test_id" in
        CP-01|CP-02|CP-03|CP-04)
            log_info "Cross-platform test $test_id requires results from all platforms"
            record_result "$test_id" "BLOCKED" "Requires comparison with other platforms"
            ;;
        *)
            record_result "$test_id" "BLOCKED" "Test not recognized"
            ;;
    esac
}

# Create test SVG files
create_test_svg() {
    local test_id="$1"
    local output="$2"
    
    case "$test_id" in
        ST-01)
            # SVG with script tag
            cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <script>alert('test')</script>
  <rect width="100" height="100" fill="red"/>
</svg>
EOF
            ;;
        ST-02)
            # SVG with event handler
            cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" onload="alert('test')">
  <rect width="100" height="100" fill="red"/>
</svg>
EOF
            ;;
        ST-03)
            # SVG with foreignObject
            cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <foreignObject width="100" height="100">
    <div xmlns="http://www.w3.org/1999/xhtml">Test</div>
  </foreignObject>
</svg>
EOF
            ;;
        ST-04)
            # SVG with DTD
            cat > "$output" <<'EOF'
<!DOCTYPE svg [
  <!ENTITY x SYSTEM 'file:///etc/passwd'>
]>
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <rect width="100" height="100" fill="red"/>
</svg>
EOF
            ;;
        ST-05)
            # SVG with external entity (inline)
            cat > "$output" <<'EOF'
<!DOCTYPE svg [
  <!ENTITY x SYSTEM "file:///etc/passwd">
]>
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <rect width="100" height="100" fill="red"/>
  <text>&x;</text>
</svg>
EOF
            ;;
        ST-06)
            # SVG with JavaScript URL
            cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <a href="javascript:alert('test')">
    <rect width="100" height="100" fill="red"/>
  </a>
</svg>
EOF
            ;;
        ST-07)
            # SVG with CSS expression
            cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <style>
    rect { width: expression(alert('test')); }
  </style>
  <rect width="100" height="100" fill="red"/>
</svg>
EOF
            ;;
        ST-08)
            # SVG with nested SVG in data URL
            cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <image href="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiBmaWxsPSJyZWQiLz4=" width="100" height="100"/>
</svg>
EOF
            ;;
        ST-09)
            # Multiple SESM blocks
            cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <metadata id="sesm">{"sesm_version":"0.3.0"}</metadata>
  <metadata id="sesm">{"sesm_version":"0.3.0"}</metadata>
  <rect width="100" height="100" fill="red"/>
</svg>
EOF
            ;;
        ST-10)
            # SESM with child elements
            cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <metadata id="sesm">
    <child>This is XML, not JSON</child>
  </metadata>
  <rect width="100" height="100" fill="red"/>
</svg>
EOF
            ;;
        *)
            log_warning "No test SVG generator for $test_id"
            ;;
    esac
    
    echo "Created test file: $output"
}

# Create helper files
create_deep_xml() {
    local output="$1"
    local depth="$2"
    
    # Create a simple script to generate deep XML
    cat > "$output" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
EOF
    
    for ((i=0; i<depth; i++)); do
        echo "  <g>" >> "$output"
    done
    
    echo "  <rect width=\"100\" height=\"100\" fill=\"red\"/>" >> "$output"
    
    for ((i=0; i<depth; i++)); do
        echo "  </g>" >> "$output"
    done
    
    echo "</svg>" >> "$output"
    
    echo "Created deep XML file with depth $depth: $output"
}

create_oversized_metadata() {
    local output="$1"
    
    # Create SVG with metadata near 64 KiB limit
    cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <metadata id="sesm"><![CDATA[
EOF
    
    # Add ~60 KiB of JSON data
    for ((i=0; i<2000; i++)); do
        echo "    \"key_$i\": \"value_$(printf '%04d' $i)\"," >> "$output"
    done
    
    # Close JSON and metadata
    echo '    "sesm_version": "0.3.0"' >> "$output"
    echo '  ]]></metadata>' >> "$output"
    echo '  <rect width="100" height="100" fill="red"/>' >> "$output"
    echo '</svg>' >> "$output"
    
    echo "Created oversized metadata file: $output"
}

create_oversized_svg() {
    local output="$1"
    
    # Create SVG at max size (5 MiB)
    # Use a simple pattern repeated
    dd if=/dev/zero bs=1024 count=5120 2>/dev/null | base64 > "$output.tmp" || {
        # Fallback: create a large but valid SVG
        cat > "$output" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="10000" height="10000">
EOF
        for ((i=0; i<1000; i++)); do
            echo "  <rect x=\"$i\" y=\"0\" width=\"1\" height=\"10000\" fill=\"red\"/>" >> "$output"
        done
        echo '</svg>' >> "$output"
        rm -f "$output.tmp"
        return
    }
    
    # Create proper SVG with the base64 data
    cat > "$output" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <image href="data:image/png;base64,$(cat $output.tmp)" width="100" height="100"/>
</svg>
EOF
    
    rm -f "$output.tmp"
    echo "Created oversized SVG file: $output"
}

# Record test result
record_result() {
    local test_id="$1"
    local status="$2"
    local message="$3"
    
    local result_file="$EVIDENCE_DIR/results/${test_id}-${TIMESTAMP}.json"
    
    cat > "$result_file" <<EOF
{
  "test_id": "$test_id",
  "status": "$status",
  "message": "$message",
  "timestamp": "$TIMESTAMP",
  "platform": "$PLATFORM"
}
EOF
    
    case "$status" in
        PASS|PASS*)
            log_success "Test $test_id: $status - $message"
            ;;
        FAIL|FAIL*)
            log_error "Test $test_id: $status - $message"
            ;;
        SKIP|SKIPPED)
            log_warning "Test $test_id: $status - $message"
            ;;
        BLOCK|BLOCKED)
            log_info "Test $test_id: $status - $message"
            ;;
        *)
            log_info "Test $test_id: $status - $message"
            ;;
    esac
}

# Print summary
print_summary() {
    echo ""
    echo "=========================================================="
    echo "  Test Summary"
    echo "=========================================================="
    echo ""
    
    # Count results
    local pass_count=$(find "$RESULTS_DIR" -name "*.json" -exec grep -l '"status": "PASS"' {} \; 2>/dev/null | wc -l)
    local fail_count=$(find "$RESULTS_DIR" -name "*.json" -exec grep -l '"status": "FAIL"' {} \; 2>/dev/null | wc -l)
    local skip_count=$(find "$RESULTS_DIR" -name "*.json" -exec grep -l '"status": "SKIP"' {} \; 2>/dev/null | wc -l)
    local block_count=$(find "$RESULTS_DIR" -name "*.json" -exec grep -l '"status": "BLOCK"' {} \; 2>/dev/null | wc -l)
    
    echo "  Total Tests:  $(($pass_count + $fail_count + $skip_count + $block_count))"
    echo "  PASS:         $pass_count"
    echo "  FAIL:         $fail_count"
    echo "  SKIPPED:      $skip_count"
    echo "  BLOCKED:      $block_count"
    echo ""
    
    if [ $fail_count -eq 0 ]; then
        log_success "All tests passed or were blocked/skipped!"
    else
        log_error "$fail_count test(s) failed!"
    fi
    
    echo ""
    echo "Results stored in: $RESULTS_DIR/"
    echo "Evidence stored in: $EVIDENCE_DIR/"
}

# Run main
main
