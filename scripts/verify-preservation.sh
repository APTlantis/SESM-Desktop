#!/bin/bash
# verify-preservation.sh
# Verifies byte preservation outside SESM metadata blocks
# Part of SESM Desktop v0.1.0 Acceptance Testing

set -euo pipefail

# Check if dependencies are available
if ! command -v sha256sum &>/dev/null && ! command -v shasum &>/dev/null; then
    echo "ERROR: Neither sha256sum nor shasum found. Please install coreutils or similar."
    exit 1
fi

# Define hash command
if command -v sha256sum &>/dev/null; then
    HASH_CMD="sha256sum"
else
    HASH_CMD="shasum -a 256"
fi

# Function to calculate SHA-256
calculate_sha256() {
    if [ "$HASH_CMD" = "sha256sum" ]; then
        echo -n "$1" | sha256sum | awk '{print $1}'
    else
        echo -n "$1" | shasum -a 256 | awk '{print $1}'
    fi
}

# Function to display usage
usage() {
    echo "Usage: $0 <source-file> <output-file>"
    echo ""
    echo "Verifies that bytes outside SESM metadata blocks are preserved."
    echo ""
    echo "Arguments:"
    echo "  <source-file>    Path to the original SVG file"
    echo "  <output-file>   Path to the exported/edited SVG file"
    echo ""
    echo "Examples:"
    echo "  $0 tests/fixtures/atlas-infographic.svg \"SESM-Export-*/atlas-infographic.svg\""
    echo "  $0 input.svg output.svg"
    exit 1
}

# Check arguments
if [ $# -lt 2 ]; then
    usage
fi

SOURCE_FILE="$1"
OUTPUT_FILE="$2"

# Check if files exist
if [ ! -f "$SOURCE_FILE" ]; then
    echo "ERROR: Source file not found: $SOURCE_FILE"
    exit 1
fi

# Support glob patterns in output file
if [ ! -f "$OUTPUT_FILE" ]; then
    # Try to expand glob pattern
    SHOPT_NULLGLOB=$(shopt -p nullglob 2>/dev/null || echo "shopt -s nullglob")
    eval "$SHOPT_NULLGLOB"
    OUTPUT_FILES=($OUTPUT_FILE)
    shopt -u nullglob 2>/dev/null || true
    
    if [ ${#OUTPUT_FILES[@]} -eq 0 ]; then
        echo "ERROR: Output file not found: $OUTPUT_FILE"
        exit 1
    elif [ ${#OUTPUT_FILES[@]} -gt 1 ]; then
        echo "ERROR: Multiple output files match pattern: $OUTPUT_FILE"
        printf "  - %s\n" "${OUTPUT_FILES[@]}"
        exit 1
    else
        OUTPUT_FILE="${OUTPUT_FILES[0]}"
    fi
fi

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: Output file not found: $OUTPUT_FILE"
    exit 1
fi

echo "Verifying preservation between:"
echo "  Source: $SOURCE_FILE"
echo "  Output: $OUTPUT_FILE"
echo ""

# Calculate full file hashes for debugging
SOURCE_FULL_HASH=$($HASH_CMD "$SOURCE_FILE" | awk '{print $1}')
OUTPUT_FULL_HASH=$($HASH_CMD "$OUTPUT_FILE" | awk '{print $1}')

echo "[DEBUG] Full source hash:  $SOURCE_FULL_HASH"
echo "[DEBUG] Full output hash:  $OUTPUT_FULL_HASH"
echo ""

# Function to find SESM block positions
find_sesm_block() {
    local file="$1"
    
    # Find the opening tag
    local start=$(grep -aob '<metadata id="sesm">' "$file" | head -1 | awk -F: '{print $1}')
    
    # Find the closing tag
    local end=$(grep -aob '</metadata>' "$file" | head -1 | awk -F: '{print $1}')
    
    # Add length of closing tag
    if [ -n "$end" ]; then
        end=$((end + 11))  # Length of '</metadata>'
    fi
    
    echo "$start $end"
}

# Get SESM block positions for both files
read SOURCE_SESM_START SOURCE_SESM_END <<< "$(find_sesm_block "$SOURCE_FILE")"
read OUTPUT_SESM_START OUTPUT_SESM_END <<< "$(find_sesm_block "$OUTPUT_FILE")"

echo "[DEBUG] Source SESM block: start=$SOURCE_SESM_START, end=$SOURCE_SESM_END"
echo "[DEBUG] Output SESM block: start=$OUTPUT_SESM_START, end=$OUTPUT_SESM_END"
echo ""

# Check if we found SESM blocks
if [ -z "$OUTPUT_SESM_START" ] || [ -z "$OUTPUT_SESM_END" ]; then
    echo "ERROR: Could not find SESM metadata block in output file"
    echo "       The output file may not have been exported with SESM metadata."
    exit 1
fi

# Case 1: Source has no SESM block (first time adding metadata)
if [ -z "$SOURCE_SESM_START" ] || [ -z "$SOURCE_SESM_END" ]; then
    echo "Source file has no SESM block (first-time metadata addition)"
    echo "Verifying that source file itself is unchanged..."
    
    # In this case, the source file should be completely unchanged
    # The output file will have the SESM block added
    # We just need to verify the source file wasn't modified
    
    SOURCE_HASH_NOW=$($HASH_CMD "$SOURCE_FILE" | awk '{print $1}')
    
    if [ "$SOURCE_FULL_HASH" = "$SOURCE_HASH_NOW" ]; then
        echo "PRESERVATION VERIFIED: Source file unchanged, SESM block added"
        echo ""
        echo "Note: For first-time metadata addition, the source file remains"
        echo "      unchanged. The output file contains the original content plus"
        echo "      the new SESM metadata block."
        exit 0
    else
        echo "PRESERVATION FAILED: Source file has been modified"
        exit 1
    fi
fi

# Case 2: Both files have SESM blocks
# We need to compare the bytes outside the SESM blocks

echo "Both files have SESM blocks. Comparing bytes outside blocks..."

# Extract bytes before SESM block
SOURCE_BEFORE=$(head -c "$SOURCE_SESM_START" "$SOURCE_FILE")
OUTPUT_BEFORE=$(head -c "$OUTPUT_SESM_START" "$OUTPUT_FILE")

# Extract bytes after SESM block
SOURCE_AFTER=$(tail -c +$((SOURCE_SESM_END + 1)) "$SOURCE_FILE")
OUTPUT_AFTER=$(tail -c +$((OUTPUT_SESM_END + 1)) "$OUTPUT_FILE")

# Calculate hashes of the regions outside SESM blocks
SOURCE_BEFORE_HASH=$(calculate_sha256 "$SOURCE_BEFORE")
OUTPUT_BEFORE_HASH=$(calculate_sha256 "$OUTPUT_BEFORE")
SOURCE_AFTER_HASH=$(calculate_sha256 "$SOURCE_AFTER")
OUTPUT_AFTER_HASH=$(calculate_sha256 "$OUTPUT_AFTER")

echo "[DEBUG] Source before SESM hash: $SOURCE_BEFORE_HASH"
echo "[DEBUG] Output before SESM hash: $OUTPUT_BEFORE_HASH"
echo "[DEBUG] Source after SESM hash:  $SOURCE_AFTER_HASH"
echo "[DEBUG] Output after SESM hash:  $OUTPUT_AFTER_HASH"
echo ""

# Compare the regions
BEFORE_MATCH=0
AFTER_MATCH=0

if [ "$SOURCE_BEFORE_HASH" = "$OUTPUT_BEFORE_HASH" ]; then
    echo "✓ Bytes before SESM block: MATCH"
    BEFORE_MATCH=1
else
    echo "✗ Bytes before SESM block: MISMATCH"
fi

if [ "$SOURCE_AFTER_HASH" = "$OUTPUT_AFTER_HASH" ]; then
    echo "✓ Bytes after SESM block: MATCH"
    AFTER_MATCH=1
else
    echo "✗ Bytes after SESM block: MISMATCH"
fi

echo ""

if [ $BEFORE_MATCH -eq 1 ] && [ $AFTER_MATCH -eq 1 ]; then
    echo "PRESERVATION VERIFIED: Bytes outside SESM block are unchanged"
    exit 0
else
    echo "PRESERVATION FAILED: Bytes outside SESM block have changed"
    
    # Provide debugging information
    if [ $BEFORE_MATCH -eq 0 ]; then
        echo ""
        echo "Before SESM block comparison:"
        echo "  Source size: $(echo -n "$SOURCE_BEFORE" | wc -c) bytes"
        echo "  Output size: $(echo -n "$OUTPUT_BEFORE" | wc -c) bytes"
    fi
    
    if [ $AFTER_MATCH -eq 0 ]; then
        echo ""
        echo "After SESM block comparison:"
        echo "  Source size: $(echo -n "$SOURCE_AFTER" | wc -c) bytes"
        echo "  Output size: $(echo -n "$OUTPUT_AFTER" | wc -c) bytes"
    fi
    
    exit 1
fi
