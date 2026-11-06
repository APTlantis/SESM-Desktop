#!/bin/bash
# collect-dependencies.sh
# Collects all dependency versions for evidence collection
# Part of SESM Desktop v0.1.0 Acceptance Testing

set -euo pipefail

# Determine platform
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
EVIDENCE_DIR="evidence/local/${PLATFORM}"

# Create evidence directory if it doesn't exist
mkdir -p "$EVIDENCE_DIR"

# Output file
OUTPUT_FILE="$EVIDENCE_DIR/dependencies.json"

echo "Collecting dependency versions for platform: $PLATFORM"
echo "Timestamp: $TIMESTAMP"
echo "Output: $OUTPUT_FILE"

# Start JSON
cat > "$OUTPUT_FILE" <<'EOF'
{
  "platform": "PLATFORM_PLACEHOLDER",
  "collected_at": "TIMESTAMP_PLACEHOLDER",
  "dependencies": {
EOF

# Function to add a dependency
add_dep() {
    local name="$1"
    local version="$2"
    local command="$3"
    
    # Escape backslashes for JSON
    version=$(echo "$version" | sed 's/\\/\\\\/g')
    command=$(echo "$command" | sed 's/\\/\\\\/g')
    
    cat >> "$OUTPUT_FILE" <<EOF
    "$name": {
      "version": "$version",
      "command": "$command"
    },
EOF
}

# Function to handle missing dependencies
add_dep_missing() {
    local name="$1"
    local command="$2"
    
    command=$(echo "$command" | sed 's/\\/\\\\/g')
    
    cat >> "$OUTPUT_FILE" <<EOF
    "$name": {
      "version": null,
      "command": "$command",
      "error": "Dependency not found"
    },
EOF
}

echo "Collecting versions..."

# Platform-specific collections
if [ "$PLATFORM" = "linux" ]; then
    echo "  [Linux] Collecting system information..."
    
    # OS information
    OS_NAME=$(lsb_release -si 2>/dev/null || echo "Unknown")
    OS_VERSION=$(lsb_release -sr 2>/dev/null || echo "Unknown")
    OS_RELEASE=$(lsb_release -sd 2>/dev/null || echo "Unknown")
    
    # Kernel
    KERNEL_VERSION=$(uname -r 2>/dev/null || echo "Unknown")
    KERNEL_NAME=$(uname -s 2>/dev/null || echo "Unknown")
    
    # CPU
    CPU_MODEL=$(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2 | sed 's/^[ \t]*//' || echo "Unknown")
    CPU_CORES=$(nproc 2>/dev/null || echo "Unknown")
    CPU_ARCH=$(uname -m 2>/dev/null || echo "Unknown")
    
    # Memory
    MEM_TOTAL=$(free -b 2>/dev/null | awk '/^Mem:/{print $2}' || echo "Unknown")
    MEM_AVAILABLE=$(free -b 2>/dev/null | awk '/^Mem:/{print $7}' || echo "Unknown")
    
    # Disk
    DISK_TOTAL=$(df -B1 / 2>/dev/null | awk 'NR==2{print $2}' || echo "Unknown")
    DISK_AVAILABLE=$(df -B1 / 2>/dev/null | awk 'NR==2{print $4}' || echo "Unknown")
    
    # Now collect dependency versions
    echo "  [Linux] Collecting dependencies..."
    
    # Node.js
    if command -v node &>/dev/null; then
        NODE_VERSION=$(node --version 2>&1)
        add_dep "nodejs" "$NODE_VERSION" "node --version"
    else
        add_dep_missing "nodejs" "node --version"
    fi
    
    # npm
    if command -v npm &>/dev/null; then
        NPM_VERSION=$(npm --version 2>&1)
        add_dep "npm" "$NPM_VERSION" "npm --version"
    else
        add_dep_missing "npm" "npm --version"
    fi
    
    # Rust
    if command -v rustc &>/dev/null; then
        RUSTC_VERSION=$(rustc --version 2>&1)
        add_dep "rustc" "$RUSTC_VERSION" "rustc --version"
    else
        add_dep_missing "rustc" "rustc --version"
    fi
    
    # Cargo
    if command -v cargo &>/dev/null; then
        CARGO_VERSION=$(cargo --version 2>&1)
        add_dep "cargo" "$CARGO_VERSION" "cargo --version"
    else
        add_dep_missing "cargo" "cargo --version"
    fi
    
    # Git
    if command -v git &>/dev/null; then
        GIT_VERSION=$(git --version 2>&1)
        add_dep "git" "$GIT_VERSION" "git --version"
    else
        add_dep_missing "git" "git --version"
    fi
    
    # GCC
    if command -v gcc &>/dev/null; then
        GCC_VERSION=$(gcc --version 2>&1 | head -1)
        add_dep "gcc" "$GCC_VERSION" "gcc --version"
    else
        add_dep_missing "gcc" "gcc --version"
    fi
    
    # pkg-config
    if command -v pkg-config &>/dev/null; then
        PKG_CONFIG_VERSION=$(pkg-config --version 2>&1)
        add_dep "pkg-config" "$PKG_CONFIG_VERSION" "pkg-config --version"
    else
        add_dep_missing "pkg-config" "pkg-config --version"
    fi
    
    # WebKitGTK (check if header exists)
    if [ -f /usr/include/webkit2/webkit2.h ]; then
        WEBKITGTK_VERSION=$(pkg-config --modversion webkit2gtk-4.1 2>&1 || echo "Installed (version unknown)")
        add_dep "libwebkit2gtk-4.1" "$WEBKITGTK_VERSION" "pkg-config --modversion webkit2gtk-4.1"
    else
        add_dep_missing "libwebkit2gtk-4.1" "pkg-config --modversion webkit2gtk-4.1"
    fi
    
    # GTK
    if pkg-config --exists gtk+-3.0 2>/dev/null; then
        GTK_VERSION=$(pkg-config --modversion gtk+-3.0 2>&1)
        add_dep "libgtk-3-dev" "$GTK_VERSION" "pkg-config --modversion gtk+-3.0"
    else
        add_dep_missing "libgtk-3-dev" "pkg-config --modversion gtk+-3.0"
    fi

elif [ "$PLATFORM" = "darwin" ]; then
    echo "  [macOS] Collecting system information..."
    
    # OS information
    OS_NAME=$(sw_vers -productName 2>/dev/null || echo "Unknown")
    OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
    OS_BUILD=$(sw_vers -buildVersion 2>/dev/null || echo "Unknown")
    
    # Kernel
    KERNEL_VERSION=$(uname -r 2>/dev/null || echo "Unknown")
    
    # CPU
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")
    CPU_ARCH=$(uname -m 2>/dev/null || echo "Unknown")
    
    # Memory
    MEM_TOTAL=$(sysctl -n hw.memsize 2>/dev/null || echo "Unknown")
    
    # Disk
    DISK_TOTAL=$(df -B1 / 2>/dev/null | awk 'NR==2{print $2}' || echo "Unknown")
    DISK_AVAILABLE=$(df -B1 / 2>/dev/null | awk 'NR==2{print $4}' || echo "Unknown")
    
    echo "  [macOS] Collecting dependencies..."
    
    # Node.js
    if command -v node &>/dev/null; then
        NODE_VERSION=$(node --version 2>&1)
        add_dep "nodejs" "$NODE_VERSION" "node --version"
    else
        add_dep_missing "nodejs" "node --version"
    fi
    
    # npm
    if command -v npm &>/dev/null; then
        NPM_VERSION=$(npm --version 2>&1)
        add_dep "npm" "$NPM_VERSION" "npm --version"
    else
        add_dep_missing "npm" "npm --version"
    fi
    
    # Rust
    if command -v rustc &>/dev/null; then
        RUSTC_VERSION=$(rustc --version 2>&1)
        add_dep "rustc" "$RUSTC_VERSION" "rustc --version"
    else
        add_dep_missing "rustc" "rustc --version"
    fi
    
    # Cargo
    if command -v cargo &>/dev/null; then
        CARGO_VERSION=$(cargo --version 2>&1)
        add_dep "cargo" "$CARGO_VERSION" "cargo --version"
    else
        add_dep_missing "cargo" "cargo --version"
    fi
    
    # Git
    if command -v git &>/dev/null; then
        GIT_VERSION=$(git --version 2>&1)
        add_dep "git" "$GIT_VERSION" "git --version"
    else
        add_dep_missing "git" "git --version"
    fi
    
    # Homebrew
    if command -v brew &>/dev/null; then
        BREW_VERSION=$(brew --version 2>&1)
        add_dep "homebrew" "$BREW_VERSION" "brew --version"
    else
        add_dep_missing "homebrew" "brew --version"
    fi
    
    # Xcode CLI Tools
    if xcode-select -p &>/dev/null; then
        Xcode_PATH=$(xcode-select -p 2>&1)
        add_dep "xcode_cli_tools" "$Xcode_PATH" "xcode-select -p"
    else
        add_dep_missing "xcode_cli_tools" "xcode-select -p"
    fi
else
    echo "  [Unknown Platform] Collecting basic dependencies..."
    
    # Try to collect what we can
    if command -v node &>/dev/null; then
        NODE_VERSION=$(node --version 2>&1)
        add_dep "nodejs" "$NODE_VERSION" "node --version"
    else
        add_dep_missing "nodejs" "node --version"
    fi
    
    if command -v npm &>/dev/null; then
        NPM_VERSION=$(npm --version 2>&1)
        add_dep "npm" "$NPM_VERSION" "npm --version"
    else
        add_dep_missing "npm" "npm --version"
    fi
    
    if command -v rustc &>/dev/null; then
        RUSTC_VERSION=$(rustc --version 2>&1)
        add_dep "rustc" "$RUSTC_VERSION" "rustc --version"
    else
        add_dep_missing "rustc" "rustc --version"
    fi
    
    if command -v cargo &>/dev/null; then
        CARGO_VERSION=$(cargo --version 2>&1)
        add_dep "cargo" "$CARGO_VERSION" "cargo --version"
    else
        add_dep_missing "cargo" "cargo --version"
    fi
    
    if command -v git &>/dev/null; then
        GIT_VERSION=$(git --version 2>&1)
        add_dep "git" "$GIT_VERSION" "git --version"
    else
        add_dep_missing "git" "git --version"
    fi
fi

# Add system information as a special section
cat >> "$OUTPUT_FILE" <<EOF
    "system_info": {
      "os_name": "$OS_NAME",
      "os_version": "$OS_VERSION",
      "os_release": "$OS_RELEASE",
      "kernel_version": "$KERNEL_VERSION",
      "kernel_name": "$KERNEL_NAME",
      "cpu_model": "$CPU_MODEL",
      "cpu_cores": $CPU_CORES,
      "cpu_arch": "$CPU_ARCH",
      "memory_total_bytes": $MEM_TOTAL,
      "memory_available_bytes": $MEM_AVAILABLE,
      "disk_total_bytes": $DISK_TOTAL,
      "disk_available_bytes": $DISK_AVAILABLE
    }
EOF

# Close JSON (remove trailing comma from last dependency and add closing braces)
# We'll use a trick: read the file, remove the last comma, then close it
TEMP_FILE=$(mktemp)
sed '$ s/,$//' "$OUTPUT_FILE" > "$TEMP_FILE"
cat >> "$TEMP_FILE" <<EOF
  }
}
EOF
mv "$TEMP_FILE" "$OUTPUT_FILE"

# Replace placeholders
sed -i "s/PLATFORM_PLACEHOLDER/$PLATFORM/" "$OUTPUT_FILE"
sed -i "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/" "$OUTPUT_FILE"

echo "Dependency collection complete!"
echo "Output file: $OUTPUT_FILE"
echo ""
echo "Collected $(jq '.dependencies | keys | length' "$OUTPUT_FILE") dependencies"
