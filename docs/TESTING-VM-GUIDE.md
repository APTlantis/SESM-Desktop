# SESM Desktop — VM Testing Guide

**Document Version:** 1.0  
**Date:** 2026-11-06  
**Status:** Ready for Use  
**Purpose:** Enable credible cross-platform testing on Linux and macOS using VMs

---

## 1. Overview

This guide provides step-by-step instructions for setting up Virtual Machines (VMs) to test SESM Desktop v0.1.0 on Linux and macOS. The goal is to create reproducible, isolated test environments that can credibly demonstrate cross-platform functionality for DRS release acceptance.

### 1.1 Why VMs?

- **Isolation:** Prevent test environment contamination
- **Reproducibility:** Exact same environment can be recreated
- **Credibility:** Evidence collected in clean, documented environments
- **Cost-effective:** No need for dedicated physical hardware
- **Accessibility:** macOS can be tested on non-Apple hardware (ARM)

### 1.2 Target Platforms

| Platform | VM Software | Notes |
|----------|--------------|-------|
| Linux (Ubuntu 22.04) | VMware Workstation Player, VirtualBox, QEMU/KVM | Free options available |
| macOS (Ventura 13+) | UTM (ARM), VMware Fusion (Intel) | UTM for Apple Silicon |

---

## 2. Prerequisites

### 2.1 Host Machine Requirements

#### For Linux VM
- **CPU:** 2+ cores (4 recommended)
- **RAM:** 4 GB minimum (8 GB recommended)
- **Storage:** 20 GB minimum (50 GB recommended for disk space tests)
- **OS:** Windows 10/11, macOS, or Linux host

#### For macOS VM (UTM on ARM)
- **CPU:** Apple M1/M2/M3 (ARM64)
- **RAM:** 4 GB minimum (8 GB recommended)
- **Storage:** 32 GB minimum (macOS requires more space)
- **OS:** macOS 12+ (Monterey) host
- **UTM:** Version 4.0+

#### For macOS VM (VMware on Intel)
- **CPU:** Intel x86_64 with VT-x/AMD-V
- **RAM:** 8 GB minimum
- **Storage:** 50 GB minimum
- **OS:** macOS host (for VMware Fusion) or macOS guest on macOS host

### 2.2 Required Software

#### Common Tools
- [7-Zip](https://www.7-zip.org/) or equivalent (for extracting archives)
- [SHA-256 hash tool](https://emn178.github.io/online-tools/sha256.html) (online) or `sha256sum`/`shasum`
- Screenshot tool (Snipping Tool, Shift+Cmd+4, etc.)
- Text editor (VS Code, Notepad++, etc.)

#### Platform-Specific Tools
- **Windows:** PowerShell, WSL (optional)
- **Linux:** `sha256sum`, `git`, `curl`, `sudo`
- **macOS:** `shasum`, `git`, `curl`, Xcode Command Line Tools

---

## 3. Linux VM Setup

### 3.1 Option A: VMware Workstation Player (Recommended for Windows Hosts)

#### Step 1: Download VMware Workstation Player
- Download from: https://www.vmware.com/products/workstation-player.html
- Install on Windows host
- License: Free for personal use

#### Step 2: Download Ubuntu 22.04 LTS ISO
- Download from: https://ubuntu.com/download/desktop
- Version: Ubuntu 22.04.4 LTS (or latest 22.04.x)
- File: `ubuntu-22.04.x-desktop-amd64.iso`
- Verify SHA-256 hash against Ubuntu's published hashes

```bash
# Example hash verification (on host machine)
# Windows (PowerShell):
Get-FileHash -Algorithm SHA256 ubuntu-22.04.4-desktop-amd64.iso

# Compare with: https://releases.ubuntu.com/jammy/
```

#### Step 3: Create New VM

1. Open VMware Workstation Player
2. Click "Create a New Virtual Machine"
3. Select "Installer disc image file (ISO)"
4. Browse to Ubuntu ISO
5. Select "Linux" → "Ubuntu x64" as Guest OS
6. Name: `SESM-Test-Ubuntu-22.04`
7. Location: Choose a directory with sufficient space
8. Disk size: **50 GB** (for disk space tests)
9. Split virtual disk into multiple files: **Disabled** (for better performance)
10. Customize Hardware:
    - CPU: 2 processors
    - Memory: 4096 MB (4 GB)
    - Network: NAT (default)
    - USB: Disabled (not needed)
    - Sound: Disabled (not needed)
    - Printer: Disabled (not needed)

#### Step 4: Install Ubuntu

1. Start the VM
2. Select "Try or Install Ubuntu"
3. Language: English
4. Keyboard: English (US)
5. Installation type: **Minimal installation** (reduces attack surface)
6. Disk setup: Use entire disk (virtual disk)
7. User details:
   - Name: `sesm-tester`
   - Computer name: `sesm-test-vm`
   - Username: `tester`
   - Password: `SESM-Test-Pass-2026!` (or your secure password)
   - **Enable "Log in automatically"** (for testing convenience)
8. Wait for installation to complete
9. **DO NOT** enable online services (SSH, LivePatch)
10. Click "Restart Now"

#### Step 5: Post-Installation Setup

After Ubuntu boots:

1. Open Terminal (Ctrl+Alt+T)
2. Update system:

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Install required dependencies for Tauri
sudo apt install -y git curl gcc libwebkit2gtk-4.1-dev libgtk-3-dev \
    libayatana-appindicator3-dev pkg-config libssl-dev libstdc++6

# Install additional utilities
sudo apt install -y wget jq sha256sum htop file

# Clean up
sudo apt autoremove -y
```

3. Install Node.js 20.x:

```bash
# Install Node.js 20.x using NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version  # Should output v20.x.x
npm --version   # Should output 10.x.x or higher
```

4. Install Rust:

```bash
# Install Rust using rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Source the environment
source $HOME/.cargo/env

# Verify installation
rustc --version  # Should output rustc 1.75.x or higher
cargo --version  # Should output cargo 1.75.x or higher
```

5. Create test directory:

```bash
# Create a directory for SESM Desktop
mkdir -p ~/projects/sesm-test
cd ~/projects/sesm-test

# Clone the repository (if not already present)
# Note: In actual testing, you may copy files from host or use shared folder
```

#### Step 6: Enable Shared Folders (Optional)

For easier file transfer:

1. Shut down the VM
2. Right-click VM → Settings → Options → Shared Folders
3. Enable shared folders
4. Add a shared folder pointing to your host's SESM-Desktop directory
5. Start the VM
6. In Ubuntu, the shared folder will be at `/mnt/hgfs/`

#### Step 7: Configure Snapshot

1. Shut down the VM
2. Right-click VM → Snapshot → Take Snapshot
3. Name: `Clean-Ubuntu-22.04-Base`
4. Description: "Base Ubuntu 22.04 installation with dependencies"

**This snapshot will be used as the baseline for all Linux tests.**

---

### 3.2 Option B: VirtualBox (Free Alternative)

#### Step 1: Download and Install VirtualBox
- Download from: https://www.virtualbox.org/wiki/Downloads
- Install on host machine

#### Step 2: Create Ubuntu VM

1. Open VirtualBox
2. Click "New"
3. Name: `SESM-Test-Ubuntu-22.04`
4. Type: Linux
5. Version: Ubuntu (64-bit)
6. RAM: 4096 MB (4 GB)
7. Create a virtual hard disk: 50 GB, VDI, Dynamically allocated
8. Click "Create"

#### Step 3: Install Ubuntu

Follow the same installation steps as VMware (Section 3.1, Step 4).

#### Step 4: Install Guest Additions (for better performance)

1. After Ubuntu is installed, in VirtualBox: Devices → Insert Guest Additions CD Image
2. In Ubuntu, open a terminal and run:

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
sudo mount /dev/cdrom /mnt
sudo /mnt/VBoxLinuxAdditions.run
sudo reboot
```

#### Step 5: Post-Installation

Follow the same post-installation steps as VMware (Section 3.1, Step 5).

---

### 3.3 Option C: QEMU/KVM (Linux Hosts Only)

For Linux hosts, QEMU/KVM provides near-native performance.

#### Step 1: Install QEMU/KVM

On Ubuntu host:

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
sudo adduser $(whoami) kvm
sudo adduser $(whoami) libvirt
```

Log out and back in.

#### Step 2: Create Ubuntu VM

```bash
# Download Ubuntu ISO
wget https://releases.ubuntu.com/jammy/ubuntu-22.04.4-desktop-amd64.iso

# Create virtual disk
qemu-img create -f qcow2 sesm-test.qcow2 50G

# Create VM
virt-install \
  --name sesm-test-ubuntu \
  --ram 4096 \
  --vcpus 2 \
  --disk path=sesm-test.qcow2,size=50 \
  --os-variant ubuntu22.04 \
  --network network=default \
  --graphics spice \
  --cdrom ubuntu-22.04.4-desktop-amd64.iso
```

#### Step 3: Install Ubuntu

Follow the same installation steps as VMware.

#### Step 4: Post-Installation

After installation, install the same dependencies as Section 3.1, Step 5.

---

## 4. macOS VM Setup

### 4.1 Option A: UTM (For Apple Silicon Macs)

UTM is a free QEMU-based virtualization solution for macOS that supports ARM64.

#### Step 1: Download UTM
- Download from: https://mac.getutm.app/
- Install on macOS host (requires macOS 12+)

#### Step 2: Download macOS Installer

UTM provides pre-downloaded macOS installers:

1. Open UTM
2. Click "Create a New Virtual Machine"
3. Select "Virtualize" (not Emulate)
4. Select "Apple Silicon" as Architecture
5. Operating System: macOS
6. UTM will automatically download a macOS installer image

Alternatively, download the macOS Ventura ISO:
- Download from: https://www.insanelymac.com/forum/files/file/1480-macos-ventura-13x-final/
- **Note:** Downloading macOS ISOs may violate Apple's EULA. UTM's built-in downloader is recommended.

#### Step 3: Create macOS VM

1. In UTM, click "Create a New Virtual Machine"
2. Configuration:
   - **Virtualize:** Apple Silicon
   - **Operating System:** macOS
   - **Version:** Ventura (or latest available)
   - **Memory:** 8192 MB (8 GB)
   - **CPU Cores:** 4
   - **Storage:** 64 GB
   - **Network:** Shared Network (NAT)
   - **Graphics:** Default
   - **Sound:** Default
   - **USB:** None
3. Click "Save"

#### Step 4: Install macOS

1. Start the VM
2. Follow the macOS installation prompts
3. Create user:
   - Name: `SESM Tester`
   - Account Name: `tester`
   - Password: `SESM-Test-Pass-2026!`
   - **Do not enable FileVault** (slows down VM)
   - **Do not enable iCloud**
4. Wait for installation to complete

#### Step 5: Post-Installation Setup

After macOS boots:

1. Open Terminal (Applications → Utilities → Terminal)
2. Install Xcode Command Line Tools:

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Accept the license
sudo xcodebuild -license accept
```

3. Install Homebrew (package manager):

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zshrc
source ~/.zshrc
```

4. Install Node.js 20.x:

```bash
# Install Node.js 20.x
brew install node@20

# Link to make it default
brew link --overwrite node@20

# Verify installation
node --version  # Should output v20.x.x
npm --version   # Should output 10.x.x or higher
```

5. Install Rust:

```bash
# Install Rust using rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Source the environment
source $HOME/.cargo/env

# Verify installation
rustc --version
cargo --version
```

6. Install additional utilities:

```bash
# Install utilities
brew install wget jq sha256sum htop
```

7. Create test directory:

```bash
# Create a directory for SESM Desktop
mkdir -p ~/Projects/sesm-test
cd ~/Projects/sesm-test
```

#### Step 6: Configure File Sharing

For easier file transfer:

1. In UTM, click on the VM
2. Click "Edit" → "Sharing"
3. Enable "Directory Sharing"
4. Add a shared folder pointing to your host's SESM-Desktop directory
5. In macOS VM, the shared folder will be at `/Users/tester/Shared`

#### Step 7: Configure Snapshot

1. Shut down the VM
2. In UTM, right-click the VM → Snapshot
3. Name: `Clean-macOS-Ventura-Base`
4. Description: "Base macOS Ventura installation with dependencies"

**This snapshot will be used as the baseline for all macOS tests.**

---

### 4.2 Option B: VMware Fusion (For Intel Macs)

#### Step 1: Download VMware Fusion
- Download from: https://www.vmware.com/products/fusion.html
- Note: VMware Fusion Player is free for personal use

#### Step 2: Download macOS Installer

VMware Fusion can create macOS VMs from the recovery partition:

1. Open VMware Fusion
2. Click "Create a New Virtual Machine"
3. Select "Install from recovery partition"
4. Follow prompts to create a macOS VM

#### Step 3: Configure VM

- **Memory:** 8192 MB (8 GB)
- **CPU:** 4 processors
- **Disk:** 64 GB
- **Network:** NAT

#### Step 4: Install and Configure

Follow the same post-installation steps as UTM (Section 4.1, Step 5).

---

## 5. VM Management

### 5.1 Snapshot Strategy

Use snapshots to create checkpoints:

| Snapshot Name | Purpose | When to Create |
|----------------|---------|----------------|
| Clean-Base | Initial OS with dependencies | After post-installation setup |
| Pre-Test | Before test execution | Before each test suite |
| Post-Test-Pass | After successful test | After each test suite passes |
| Post-Test-Fail | After failed test | When a test fails (for debugging) |

### 5.2 Reverting VMs

To reset between tests:

1. **VMware:** Right-click VM → Snapshot → Revert to Snapshot → Select "Clean-Base"
2. **VirtualBox:** Right-click VM → Snapshot → Restore Snapshot → Select "Clean-Base"
3. **UTM:** Right-click VM → Revert to Snapshot → Select "Clean-Base"

### 5.3 Backing Up VMs

Create backups of VMs for archive:

1. Shut down the VM
2. Copy the entire VM directory to a backup location
3. Compress if needed (7-Zip, tar.gz)
4. Document the backup with:
   - Date
   - VM state
   - Snapshot list
   - Purpose

---

## 6. File Transfer

### 6.1 Transferring SESM Desktop to VMs

#### Option A: Shared Folders (Recommended)
- Set up shared folders as described in each VM type
- Copy SESM-Desktop directory to the shared folder
- Access from VM at the mounted location

#### Option B: Git Clone

In the VM:

```bash
# Clone the repository (if publicly accessible)
cd ~/projects/sesm-test
git clone <repository-url> SESM-Desktop
cd SESM-Desktop

# Or copy from a git server
git clone file:///path/to/local/repo SESM-Desktop
```

#### Option C: SCP (Linux/macOS VMs)

From host machine (if SSH is enabled):

```bash
# Windows (PowerShell)
scp -r C:\path\to\SESM-Desktop tester@vm-ip:~/projects/sesm-test/

# macOS/Linux
scp -r /path/to/SESM-Desktop tester@vm-ip:~/projects/sesm-test/
```

#### Option D: HTTP Server

On host machine:

```bash
# Python HTTP server
cd /path/to/parent/directory
python3 -m http.server 8000

# Or PowerShell
cd C:\path\to\parent\directory
python -m http.server 8000
```

In VM:

```bash
# Download via wget
cd ~/projects/sesm-test
wget -r -np -nH --cut-dirs=1 -R "index.html" http://host-ip:8000/SESM-Desktop/
```

---

## 7. Testing Workflow

### 7.1 Linux Testing Workflow

```bash
# 1. Navigate to project directory
cd ~/projects/sesm-test/SESM-Desktop

# 2. Install dependencies
npm ci

# 3. Run engine tests
npm run test:engine

# 4. Run frontend tests
npm test

# 5. Run browser workflow tests
npm run test:ui

# 6. Verify sources
npm run verify:sources

# 7. Build the application
npm run build

# 8. Build the desktop package
npm run tauri build

# 9. The package will be at:
#    target/release/bundle/appimage/*.AppImage
#    or
#    target/release/bundle/deb/*.deb
```

### 7.2 macOS Testing Workflow

```bash
# 1. Navigate to project directory
cd ~/Projects/sesm-test/SESM-Desktop

# 2. Install dependencies
npm ci

# 3. Run engine tests
npm run test:engine

# 4. Run frontend tests
npm test

# 5. Run browser workflow tests
npm run test:ui

# 6. Verify sources
npm run verify:sources

# 7. Build the application
npm run build

# 8. Build the desktop package
npm run tauri build

# 9. The package will be at:
#    target/release/bundle/dmg/*.dmg
#    or
#    target/release/bundle/macos/*.app
```

---

## 8. Evidence Collection

See `EVIDENCE-COLLECTION.md` for detailed procedures.

### 8.1 Quick Evidence Checklist

For each test, collect:

1. **Test Execution Log**
   - Timestamp
   - Test ID
   - Platform
   - Tester
   - Pass/Fail
   - Notes

2. **Screenshots**
   - Application window (full)
   - Specific dialogs or messages
   - Export receipt dialog
   - File explorer showing results

3. **Hashes**
   - Source file SHA-256 (before)
   - Source file SHA-256 (after)
   - Output file SHA-256
   - Package SHA-256

4. **Receipts**
   - Export receipt JSON file
   - Application logs (if applicable)

---

## 9. Troubleshooting

### 9.1 Common Issues and Solutions

#### Linux VM Issues

| Issue | Solution |
|-------|----------|
| VM won't start | Check VT-x/AMD-V is enabled in BIOS |
| Slow performance | Allocate more RAM/CPU, use SSD storage |
| Shared folders not working | Install VMware Tools/VirtualBox Guest Additions |
| Node.js installation fails | Use NodeSource or nvm instead of apt |
| Rust compilation fails | Install build-essential and libstdc++6 |
| WebKitGTK missing | Run: `sudo apt install -y libwebkit2gtk-4.1-dev` |
| Tauri build fails | Ensure all dependencies are installed from Section 3.1 |

#### macOS VM Issues (UTM)

| Issue | Solution |
|-------|----------|
| VM won't start on M1/M2 | Ensure "Virtualize" is selected (not "Emulate") |
| macOS installation fails | Use UTM's built-in macOS downloader |
| Slow performance | Allocate more RAM (8 GB minimum) |
| Shared folders not working | Enable in UTM settings, check permissions |
| Xcode CLI tools not found | Run: `xcode-select --install` |
| Homebrew installation fails | Ensure Xcode CLI tools are installed first |
| Node.js installation fails | Use: `brew install node@20` then `brew link --overwrite node@20` |

#### General Issues

| Issue | Solution |
|-------|----------|
| Build takes too long | Use `--locked` flag, ensure cargo cache is reused |
| Dependency conflicts | Delete `node_modules` and `target`, run `npm ci` and `cargo clean` |
| Permission denied | Use `chmod` or run with `sudo` (carefully) |
| Network issues in VM | Use NAT or Bridged network mode |

### 9.2 Debugging Tips

#### Check System Information

**Linux:**
```bash
# CPU
lscpu

# Memory
free -h

# Disk
df -h

# OS
lsb_release -a

# Kernel
uname -a
```

**macOS:**
```bash
# System
system_profiler SPSoftwareDataType

# CPU
sysctl -n machdep.cpu.brand_string

# Memory
sysctl hw.memsize

# Disk
df -h
```

#### Check Dependencies

```bash
# Check Node.js
node --version
npm --version

# Check Rust
rustc --version
cargo --version

# Check Git
git --version

# Check build tools (Linux)
gcc --version
pkg-config --version
```

#### Clean Build

```bash
# Full clean build
rm -rf node_modules target dist
npm ci
npm run build
cargo clean -p sesm-engine
cargo clean -p sesm-desktop
npm run tauri build
```

---

## 10. Performance Optimization

### 10.1 Speed Up VMs

1. **Allocate more resources:**
   - CPU: 4+ cores
   - RAM: 8+ GB
   - Disk: SSD-based virtual disk

2. **Enable acceleration:**
   - VT-x/AMD-V in BIOS
   - Hyper-V (Windows host)
   - KVM (Linux host)

3. **Use fixed-size disks:**
   - Pre-allocate entire disk space
   - Better performance than dynamic allocation

4. **Disable unnecessary features:**
   - Sound
   - USB
   - Printers
   - 3D graphics (use 2D for testing)

### 10.2 Speed Up Builds

1. **Use cargo cache:**
   ```bash
   # Enable cargo cache
   mkdir -p ~/.cargo
   echo 'export CARGO_HOME=$HOME/.cargo' >> ~/.bashrc
   ```

2. **Reuse build artifacts:**
   - Don't clean between rebuilds unless necessary
   - Use `cargo build` instead of `cargo clean && cargo build`

3. **Use parallel compilation:**
   ```bash
   # Export number of CPU cores
   export MAKEFLAGS=-j$(nproc)
   ```

---

## 11. Security Considerations

### 11.1 VM Security

1. **Isolate test VMs:**
   - Do not connect to production networks
   - Use NAT or Host-only networking
   - Disable Wi-Fi/Bluetooth in VM settings

2. **Use non-sensitive data:**
   - Do not use real user data in tests
   - Use test accounts, not production accounts
   - Use dummy passwords

3. **Disable automatic updates:**
   - Prevent unexpected reboots during testing
   - Control when updates are applied

4. **Regular snapshots:**
   - Easy to revert to known-good state
   - Quick recovery from malware or corruption

### 11.2 Test Data Security

1. **Use test fixtures:**
   - Provided in `tests/fixtures/`
   - Safe, known content
   - No real metadata

2. **Generate synthetic data:**
   ```bash
   # Use scripts to generate test data
   node scripts/generate-test-fixtures.mjs
   ```

3. **Never use production files:**
   - Even for "quick tests"
   - Risk of data leakage

---

## 12. VM Configuration Templates

### 12.1 Linux VM Configuration (VMware .vmx)

```ini
config.version = "8"
guestOS = "ubuntu-64"
hardwareVersion = "19"
numvcpus = "4"
memsize = "8192"
scsi0.present = "TRUE"
scsi0:0.fileName = "SESM-Test-Ubuntu-22.04.vmdk"
scsi0:0.present = "TRUE"
scsi0:0.redolog = "TRUE"
scsi0:0.size = "53687091200"  # 50 GB
ide1:0.present = "TRUE"
ide1:0.fileName = "ubuntu-22.04.4-desktop-amd64.iso"
ide1:0.deviceType = "cdrom-image"
etworkSettings.natService = "TRUE"
```

### 12.2 UTM Configuration (macOS)

```json
{
  "name": "SESM-Test-macOS",
  "target": "utm",
  "architecture": "aarch64",
  "machine": "virt",
  "accel": true,
  "cpu": 4,
  "memory": 8192,
  "drive": {
    "interface": "virtio",
    "size": 68719476736,
    "file": "SESM-Test-macOS.qcow2"
  },
  "network": {
    "mode": "shared"
  },
  "graphics": {
    "type": "spice"
  }
}
```

---

## 13. Checklist

Use this checklist to verify VM setup:

### Linux VM
- [ ] Ubuntu 22.04 LTS installed
- [ ] User `tester` created with auto-login
- [ ] Network configured (NAT)
- [ ] Node.js 20.x installed
- [ ] npm 10.x installed
- [ ] Git installed
- [ ] Rust 1.75+ installed
- [ ] Cargo 1.75+ installed
- [ ] Build dependencies installed (libwebkit2gtk-4.1-dev, etc.)
- [ ] Utilities installed (wget, jq, sha256sum, htop, file)
- [ ] SESM Desktop repository cloned/accessible
- [ ] Snapshot "Clean-Ubuntu-22.04-Base" created
- [ ] Shared folders configured (optional)

### macOS VM
- [ ] macOS Ventura 13+ installed
- [ ] User `tester` created
- [ ] Network configured (NAT)
- [ ] Xcode Command Line Tools installed
- [ ] Homebrew installed
- [ ] Node.js 20.x installed
- [ ] Rust 1.75+ installed
- [ ] Cargo 1.75+ installed
- [ ] Utilities installed (wget, jq, sha256sum, htop)
- [ ] SESM Desktop repository cloned/accessible
- [ ] Snapshot "Clean-macOS-Ventura-Base" created
- [ ] Shared folders configured (optional)

### Test Readiness
- [ ] VM boots successfully
- [ ] Network connectivity verified
- [ ] All dependencies verified (`node --version`, `npm --version`, `rustc --version`)
- [ ] SESM Desktop files accessible
- [ ] Test fixtures available
- [ ] Evidence collection tools ready (screenshot, hash tools)

---

## 14. Next Steps

After VM setup is complete:

1. **Review the Test Plan** (`docs/TEST-PLAN.md`)
2. **Set up evidence collection** (`docs/EVIDENCE-COLLECTION.md`)
3. **Execute tests** following the test plan
4. **Collect evidence** for each test
5. **Document results** in the validation report
6. **Update acceptance status** in `Validation-Checklist.md`

---

**Document Status:** Ready for use  
**Last Updated:** 2026-11-06  
**Owner:** SESM Desktop Team  
**Related Documents:**
- `TEST-PLAN.md` - Comprehensive test definitions
- `EVIDENCE-COLLECTION.md` - Evidence collection procedures
- `LINUX-ACCEPTANCE.md` - Linux-specific acceptance criteria
- `MACOS-ACCEPTANCE.md` - macOS-specific acceptance criteria
