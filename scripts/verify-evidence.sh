#!/bin/bash
# verify-evidence.sh
# Verifies the integrity of all collected evidence for SESM Desktop v0.1.0
# Part of DRS Phase 4 Release Readiness

set -euo pipefail

# Configuration
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
EVIDENCE_DIR="$PROJECT_ROOT/evidence"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_FILES=0
VALIDATED_FILES=0
INVALID_FILES=0
WARNINGS=0

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
    echo "  SESM Desktop v0.1.0 - Evidence Verification"
    echo "=========================================================="
    echo ""
}

# Print summary
print_summary() {
    echo ""
    echo "=========================================================="
    echo "  Evidence Verification Summary"
    echo "=========================================================="
    echo ""
    echo "  Total Files Checked:   $TOTAL_FILES"
    echo "  Valid Files:           $VALIDATED_FILES"
    echo "  Invalid Files:         $INVALID_FILES"
    echo "  Warnings:              $WARNINGS"
    echo ""
    
    if [ $INVALID_FILES -eq 0 ]; then
        log_success "All evidence validated successfully!"
        exit 0
    else
        log_error "$INVALID_FILES file(s) failed validation!"
        exit 1
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Verify hash files
hash_correct=true
verify_hash_files() {
    local hash_dir="$1"
    
    log_info "Verifying hash files in: $hash_dir"
    
    # Find all .sha256 files
    local hash_files=$(find "$hash_dir" -name "*.sha256" -type f 2>/dev/null)
    
    if [ -z "$hash_files" ]; then
        log_info "No hash files found in $hash_dir"
        return
    fi
    
    for hash_file in $hash_files; do
        TOTAL_FILES=$((TOTAL_FILES + 1))
        
        # Read the hash file
        if [ ! -f "$hash_file" ]; then
            log_error "Hash file not found: $hash_file"
            INVALID_FILES=$((INVALID_FILES + 1))
            continue
        fi
        
        # Extract expected hash and filename
        local line=$(head -1 "$hash_file")
        local expected_hash=$(echo "$line" | awk '{print $1}')
        local file_to_check=$(echo "$line" | awk '{print $2}')
        
        # Check if the file exists
        if [ ! -f "$file_to_check" ]; then
            # Try relative path from hash file directory
            local dir=$(dirname "$hash_file")
            local base=$(basename "$file_to_check")
            file_to_check="$dir/$base"
        fi
        
        if [ ! -f "$file_to_check" ]; then
            log_error "Referenced file not found: $file_to_check (from $hash_file)"
            INVALID_FILES=$((INVALID_FILES + 1))
            continue
        fi
        
        # Calculate actual hash
        local actual_hash=$(sha256sum "$file_to_check" 2>/dev/null | awk '{print $1}')
        
        if [ "$expected_hash" = "$actual_hash" ]; then
            VALIDATED_FILES=$((VALIDATED_FILES + 1))
            echo "  ✓ $file_to_check"
        else
            log_error "Hash mismatch for $file_to_check"
            log_error "  Expected: $expected_hash"
            log_error "  Actual:   $actual_hash"
            INVALID_FILES=$((INVALID_FILES + 1))
            hash_correct=false
        fi
    done
}

# Verify JSON files
verify_json_files() {
    local json_dir="$1"
    
    log_info "Verifying JSON files in: $json_dir"
    
    # Check if jq is available
    if ! command_exists jq; then
        log_warning "jq not installed. JSON validation will be skipped."
        WARNINGS=$((WARNINGS + 1))
        return
    fi
    
    # Find all .json files
    local json_files=$(find "$json_dir" -name "*.json" -type f 2>/dev/null)
    
    if [ -z "$json_files" ]; then
        log_info "No JSON files found in $json_dir"
        return
    fi
    
    for json_file in $json_files; do
        TOTAL_FILES=$((TOTAL_FILES + 1))
        
        # Validate JSON
        if jq empty "$json_file" 2>/dev/null; then
            VALIDATED_FILES=$((VALIDATED_FILES + 1))
            echo "  ✓ $json_file"
        else
            log_error "Invalid JSON in: $json_file"
            INVALID_FILES=$((INVALID_FILES + 1))
        fi
    done
}

# Verify PNG files
verify_png_files() {
    local png_dir="$1"
    
    log_info "Verifying PNG files in: $png_dir"
    
    # Find all .png files
    local png_files=$(find "$png_dir" -name "*.png" -type f 2>/dev/null)
    
    if [ -z "$png_files" ]; then
        log_info "No PNG files found in $png_dir"
        return
    fi
    
    for png_file in $png_files; do
        TOTAL_FILES=$((TOTAL_FILES + 1))
        
        # Check if file is a valid PNG
        if command_exists file; then
            local file_type=$(file "$png_file" 2>/dev/null)
            if echo "$file_type" | grep -q "PNG image data"; then
                VALIDATED_FILES=$((VALIDATED_FILES + 1))
                echo "  ✓ $png_file"
            else
                log_error "Invalid PNG format: $png_file"
                log_error "  Detected as: $file_type"
                INVALID_FILES=$((INVALID_FILES + 1))
            fi
        else
            # Fallback: check magic bytes
            local magic=$(head -c 8 "$png_file" 2>/dev/null | od -An -tx1 | tr -d ' ')
            if [ "$magic" = "89504e470d0a1a0a" ]; then
                VALIDATED_FILES=$((VALIDATED_FILES + 1))
                echo "  ✓ $png_file"
            else
                log_error "Invalid PNG magic bytes: $png_file"
                INVALID_FILES=$((INVALID_FILES + 1))
            fi
        fi
    done
}

# Verify log files
verify_log_files() {
    local log_dir="$1"
    
    log_info "Verifying log files in: $log_dir"
    
    # Find all .log files
    local log_files=$(find "$log_dir" -name "*.log" -type f 2>/dev/null)
    
    if [ -z "$log_files" ]; then
        log_info "No log files found in $log_dir"
        return
    fi
    
    for log_file in $log_files; do
        TOTAL_FILES=$((TOTAL_FILES + 1))
        
        # Just check that it's a non-empty text file
        if [ -s "$log_file" ]; then
            VALIDATED_FILES=$((VALIDATED_FILES + 1))
            echo "  ✓ $log_file"
        else
            log_warning "Empty log file: $log_file"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
}

# Verify receipt files
verify_receipt_files() {
    local receipt_dir="$1"
    
    log_info "Verifying receipt files in: $receipt_dir"
    
    # Find all receipt files
    local receipt_files=$(find "$receipt_dir" -name "*receipt*.json" -type f 2>/dev/null)
    
    if [ -z "$receipt_files" ]; then
        log_info "No receipt files found in $receipt_dir"
        return
    fi
    
    for receipt_file in $receipt_files; do
        TOTAL_FILES=$((TOTAL_FILES + 1))
        
        # Check if it's valid JSON and contains required fields
        if command_exists jq; then
            if jq -e '.files | length > 0' "$receipt_file" 2>/dev/null; then
                VALIDATED_FILES=$((VALIDATED_FILES + 1))
                echo "  ✓ $receipt_file"
            else
                log_error "Invalid receipt format: $receipt_file"
                INVALID_FILES=$((INVALID_FILES + 1))
            fi
        else
            # Just check it's non-empty
            if [ -s "$receipt_file" ]; then
                VALIDATED_FILES=$((VALIDATED_FILES + 1))
                echo "  ✓ $receipt_file"
            else
                log_error "Empty receipt file: $receipt_file"
                INVALID_FILES=$((INVALID_FILES + 1))
            fi
        fi
    done
}

# Verify metadata files
verify_metadata_files() {
    local metadata_dir="$1"
    
    log_info "Verifying metadata files in: $metadata_dir"
    
    # Find all metadata.json files
    local metadata_files=$(find "$metadata_dir" -name "metadata.json" -type f 2>/dev/null)
    
    if [ -z "$metadata_files" ]; then
        log_info "No metadata files found in $metadata_dir"
        return
    fi
    
    for metadata_file in $metadata_files; do
        TOTAL_FILES=$((TOTAL_FILES + 1))
        
        if command_exists jq; then
            # Check for required fields
            if jq -e '.test_id and .status and .timestamp' "$metadata_file" 2>/dev/null; then
                VALIDATED_FILES=$((VALIDATED_FILES + 1))
                echo "  ✓ $metadata_file"
            else
                log_error "Missing required fields in: $metadata_file"
                INVALID_FILES=$((INVALID_FILES + 1))
            fi
        else
            # Just check it's non-empty
            if [ -s "$metadata_file" ]; then
                VALIDATED_FILES=$((VALIDATED_FILES + 1))
                echo "  ✓ $metadata_file"
            else
                log_error "Empty metadata file: $metadata_file"
                INVALID_FILES=$((INVALID_FILES + 1))
            fi
        fi
    done
}

# Main verification
main() {
    print_banner
    
    # Check if evidence directory exists
    if [ ! -d "$EVIDENCE_DIR" ]; then
        log_error "Evidence directory not found: $EVIDENCE_DIR"
        exit 1
    fi
    
    log_info "Evidence directory: $EVIDENCE_DIR"
    echo ""
    
    # Verify evidence in local directories
    for platform in linux macos windows; do
        local_dir="$EVIDENCE_DIR/local/$platform"
        
        if [ -d "$local_dir" ]; then
            log_info "Verifying evidence for platform: $platform"
            echo ""
            
            # Verify all types of files in this platform directory
            verify_hash_files "$local_dir"
            verify_json_files "$local_dir"
            verify_png_files "$local_dir"
            verify_log_files "$local_dir"
            verify_receipt_files "$local_dir"
            verify_metadata_files "$local_dir"
            
            echo ""
        else
            log_warning "No evidence found for platform: $platform"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
    
    # Verify root evidence files
    log_info "Verifying root evidence files"
    echo ""
    verify_hash_files "$EVIDENCE_DIR"
    verify_json_files "$EVIDENCE_DIR"
    
    # Print summary
    print_summary
}

# Run main
main
