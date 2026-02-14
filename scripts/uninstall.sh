#!/bin/bash
# Node Exporter uninstallation script.
# Usage: sudo bash uninstall.sh

set -e

SERVICE_NAME="node_exporter"
BIN_NAME="node_exporter"
INSTALL_DIR="/usr/local/bin"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()    { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

if [ "$(id -u)" -ne 0 ]; then
  fail "This script must be run as root. Please use: sudo bash $0"
fi

echo ""
echo "=========================================="
echo "  Node Exporter Uninstaller"
echo "=========================================="
echo ""

# Stop and disable service
if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
  info "Stopping ${SERVICE_NAME} service..."
  systemctl stop "${SERVICE_NAME}.service"
fi

if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
  info "Disabling ${SERVICE_NAME} service..."
  systemctl disable "${SERVICE_NAME}.service"
fi

# Remove service file
if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
  info "Removing systemd service file..."
  rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
  systemctl daemon-reload
fi

# Remove binary (support both old and new naming)
if [ -f "${INSTALL_DIR}/${BIN_NAME}" ]; then
  info "Removing binary ${INSTALL_DIR}/${BIN_NAME}..."
  rm -f "${INSTALL_DIR}/${BIN_NAME}"
fi

# Also clean up legacy binary name (node_exporter_amd64) if it exists
if [ -f "${INSTALL_DIR}/${BIN_NAME}_amd64" ]; then
  info "Removing legacy binary ${INSTALL_DIR}/${BIN_NAME}_amd64..."
  rm -f "${INSTALL_DIR}/${BIN_NAME}_amd64"
fi

echo ""
info "Uninstallation complete."
echo ""
