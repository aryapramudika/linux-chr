#!/bin/bash

# Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# func
error() { echo -e "${RED}Error: $1${NC}" >&2; exit 1; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }
success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }

# Def values
CHR_VERSION="7.16.1"
USERNAME="admin"  # Fixed username
PASSWORD="admin"
DISK_DEVICE="/dev/vda"
LOOP_DEVICE="/dev/loop7"

# Helper func
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Install MikroTik RouterOS (CHR)"
    echo
    echo "Options:"
    echo "  -v, --version VERSION    CHR version to install (default: $CHR_VERSION)"
    echo "  -p, --password PASSWORD  Set admin password (default: $PASSWORD)"
    echo "  -d, --device DEVICE      Target disk device (default: $DISK_DEVICE)"
    echo "  -h, --help              Show this help message"
    echo
    echo "Example:"
    echo "  $0 -v 7.16.1 -p mypassword -d /dev/vda"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            CHR_VERSION="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -d|--device)
            DISK_DEVICE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check root
[ "$EUID" -ne 0 ] && error "Please run as root"

# Validate parameters
[[ ! $CHR_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && error "Invalid version format. Use x.x.x (e.g., 7.13.3)"
[ -z "$PASSWORD" ] && error "Password cannot be empty"
[ ! -b "$DISK_DEVICE" ] && warn "Warning: $DISK_DEVICE might not be a block device"

# Detect primary interface and network config
info "Detecting network configuration..."
INTERFACE=$(ip route get 8.8.8.8 2>/dev/null | grep -Po '(?<=dev )\w+' | head -1)
[ -z "$INTERFACE" ] && error "Could not detect network interface"

ADDRESS=$(ip addr show $INTERFACE | grep -Po 'inet \K[\d.]+/[\d]+' | head -1)
GATEWAY=$(ip route | grep default | grep -Po '(?<=via )\S+' | head -1)

# Print installation parameters
info "Installation parameters:"
echo "CHR Version: $CHR_VERSION"
echo "Username: $USERNAME (fixed)"
echo "Password: $PASSWORD"
echo "Target Device: $DISK_DEVICE"
echo "Network Interface: $INTERFACE"
echo "IP Address: $ADDRESS"
echo "Gateway: $GATEWAY"

# Confirm installation
read -p "Continue with installation? [y/N] " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && error "Installation cancelled by user"

# Download and prepare CHR
info "Downloading CHR image..."
wget "https://download.mikrotik.com/routeros/$CHR_VERSION/chr-$CHR_VERSION.img.zip" -O chr.img.zip || error "Download failed"
gunzip -c chr.img.zip > chr.img || error "Extraction failed"

# Setup loop device
info "Setting up partitions..."
losetup -P $LOOP_DEVICE chr.img || error "Loop device setup failed"

# Mount partitions and configure
info "Mounting and configuring..."
mkdir -p /mnt
mount ${LOOP_DEVICE}p1 /mnt || error "Mount partition 1 failed"
mount ${LOOP_DEVICE}p2 /mnt || error "Mount partition 2 failed"

# Create configuration
info "Creating initial configuration..."
cat > /mnt/rw/autorun.scr << EOF
/ip address add address=$ADDRESS interface=[/interface ethernet find where name=ether1]
/ip route add gateway=$GATEWAY
/ip service disable telnet
/user set 0 password=$PASSWORD
EOF

# Unmount and cleanup
info "Unmounting partitions..."
umount /mnt
losetup -d $LOOP_DEVICE

# Install to disk
info "Installing to disk..."
dd if=chr.img bs=1024 of=$DISK_DEVICE status=progress || error "Installation failed"
sync

# Cleanup files
rm -f chr.img chr.img.zip

success "Installation completed!"
info "Network configuration:"
info "Interface: $INTERFACE"
info "Address: $ADDRESS"
info "Gateway: $GATEWAY"
info "Login credentials:"
info "Username: $USERNAME (fixed)"
info "Password: $PASSWORD"
info "System will reboot in 5 seconds..."

sleep 5
echo b > /proc/sysrq-trigger