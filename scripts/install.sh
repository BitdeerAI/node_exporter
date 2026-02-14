#!/bin/bash
# Node Exporter installation script with automatic architecture detection.
# Supports linux/amd64 and linux/arm64.
#
# Usage: sudo bash install.sh [port]
#   port: listening port, defaults to 745

set -e

# ========================= Configuration =========================
VERSION="v1.1"
# SHA256 checksums for release verification (update after each build)
SHA256_AMD64="3459975e53e3e3fda3f49f5d21147429912ad3e42734be2a879573588dac9a1d"
SHA256_ARM64="1f7e13514fd804ef0f1b250c7ec1adab583d204e6d37799730956567293d5f24"

INSTALL_DIR="/usr/local/bin"
BIN_NAME="node_exporter"
SERVICE_NAME="node_exporter"
DOWNLOAD_BASE_URL="https://github.com/BitdeerAI/node_exporter/releases/download/${VERSION}"
# =================================================================

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()    { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ========================= Functions =============================

# Check root privileges
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    fail "This script must be run as root. Please use: sudo bash $0"
  fi
}

# Detect system architecture and map to Go arch name
detect_arch() {
  local machine
  machine=$(uname -m)
  case "$machine" in
    x86_64|amd64)    ARCH="amd64" ;;
    aarch64|arm64)   ARCH="arm64" ;;
    *)               fail "Unsupported architecture: $machine. Only amd64 and arm64 are supported." ;;
  esac
  info "Detected architecture: ${ARCH} (${machine})"
}

# Parse command-line arguments
parse_args() {
  PORT="${1:-745}"
  info "Listening port: ${PORT}"
}

# Get expected sha256 hash for current architecture
get_expected_hash() {
  case "$ARCH" in
    amd64) EXPECTED_HASH="$SHA256_AMD64" ;;
    arm64) EXPECTED_HASH="$SHA256_ARM64" ;;
  esac
}

# Check if node_exporter is already installed
check_existing() {
  if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
    fail "NodeExporter service is already running. Please uninstall first:\n  sudo bash uninstall.sh"
  fi
  if [ -f "${INSTALL_DIR}/${BIN_NAME}" ]; then
    fail "NodeExporter binary already exists at ${INSTALL_DIR}/${BIN_NAME}. Please uninstall first."
  fi
}

# Check required commands
check_dependencies() {
  for cmd in wget sha256sum tar systemctl; do
    if ! command -v "$cmd" &>/dev/null; then
      fail "Required command not found: ${cmd}. Please install it first."
    fi
  done
}

# Download release archive and verify its integrity
download_and_verify() {
  local pkg_name="node_exporter_${ARCH}"
  local gz_name="${pkg_name}.tar.gz"
  local file_url="${DOWNLOAD_BASE_URL}/${gz_name}"
  local tmp_file="/tmp/${gz_name}"

  # Clean up any leftover temp files
  rm -f "$tmp_file"
  rm -rf "/tmp/${pkg_name}"

  info "Downloading ${gz_name} (${VERSION})..."
  if ! wget -q --show-progress "$file_url" -O "$tmp_file"; then
    rm -f "$tmp_file"
    fail "Download failed. Please check your network connection.\n  URL: ${file_url}"
  fi

  info "Verifying file integrity (SHA256)..."
  local computed_hash
  computed_hash=$(sha256sum "$tmp_file" | awk '{print $1}')
  if [ "$computed_hash" != "$EXPECTED_HASH" ]; then
    rm -f "$tmp_file"
    fail "SHA256 verification failed!\n  Expected: ${EXPECTED_HASH}\n  Actual:   ${computed_hash}"
  fi
  info "SHA256 verification passed."

  # Extract archive
  info "Extracting archive..."
  tar -xzf "$tmp_file" -C /tmp
  rm -f "$tmp_file"

  # Install binary
  local tmp_bin="/tmp/${pkg_name}/${BIN_NAME}"
  if [ ! -f "$tmp_bin" ]; then
    rm -rf "/tmp/${pkg_name}"
    fail "Binary not found in archive. The package may be corrupted."
  fi

  chmod a+x "$tmp_bin"
  cp "$tmp_bin" "${INSTALL_DIR}/${BIN_NAME}"
  rm -rf "/tmp/${pkg_name}"

  info "Binary installed to ${INSTALL_DIR}/${BIN_NAME}"
}

# Create and start systemd service
setup_service() {
  local bin_path="${INSTALL_DIR}/${BIN_NAME}"

  info "Creating systemd service..."
  cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=${bin_path} --web.listen-address=:${PORT}
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "${SERVICE_NAME}.service"
  systemctl start "${SERVICE_NAME}.service"

  # Brief pause to let the service start
  sleep 1

  if systemctl is-active --quiet "${SERVICE_NAME}"; then
    info "Service ${SERVICE_NAME} is running."
  else
    warn "Service may not have started correctly. Check with: systemctl status ${SERVICE_NAME}"
  fi
}

# ========================= Main ==================================
main() {
  echo ""
  echo "=========================================="
  echo "  Node Exporter Installer (${VERSION})"
  echo "=========================================="
  echo ""

  check_root
  check_dependencies
  detect_arch
  parse_args "$@"
  get_expected_hash
  check_existing
  download_and_verify
  setup_service

  echo ""
  info "Installation complete! Node Exporter is running on port ${PORT}."
  echo ""
}

main "$@"
