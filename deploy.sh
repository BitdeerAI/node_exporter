#!/bin/bash
# Build and package node_exporter for multiple architectures (linux/amd64, linux/arm64).
# Usage: ./deploy.sh [version]
#   version: optional, defaults to "v1.1"
#
# Output:
#   build/node_exporter_amd64.tar.gz
#   build/node_exporter_arm64.tar.gz
#   build/install.sh          (SHA256 and version auto-filled)
#   build/sha256sums.txt

set -e

VERSION="${1:-v1.1}"
BUILD_DIR="build"
ARCHS=("amd64" "arm64")

echo "=========================================="
echo "  Node Exporter Build (${VERSION})"
echo "=========================================="
echo ""

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

for arch in "${ARCHS[@]}"; do
  echo "==> Building for linux/${arch}..."
  CGO_ENABLED=0 GOOS=linux GOARCH="${arch}" go build -o "${BUILD_DIR}/node_exporter"

  # Create package directory and move binary
  pkg_dir="${BUILD_DIR}/node_exporter_${arch}"
  mkdir -p "$pkg_dir"
  mv "${BUILD_DIR}/node_exporter" "${pkg_dir}/"

  # Create tar.gz archive
  COPYFILE_DISABLE=1 tar -czf "${BUILD_DIR}/node_exporter_${arch}.tar.gz" -C "$BUILD_DIR" "node_exporter_${arch}"
  rm -rf "$pkg_dir"

  echo "    node_exporter_${arch}.tar.gz created"
done

# Generate SHA256 checksums
echo ""
echo "==> Generating SHA256 checksums..."
cd "$BUILD_DIR"
sha256sum *.tar.gz > sha256sums.txt
echo ""
cat sha256sums.txt
cd ..

# Generate install.sh with SHA256 values populated
echo ""
echo "==> Generating install.sh..."
AMD64_HASH=$(awk '/amd64/{print $1}' "${BUILD_DIR}/sha256sums.txt")
ARM64_HASH=$(awk '/arm64/{print $1}' "${BUILD_DIR}/sha256sums.txt")

cp scripts/install.sh "${BUILD_DIR}/install.sh"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' "s|^VERSION=.*|VERSION=\"${VERSION}\"|" "${BUILD_DIR}/install.sh"
  sed -i '' "s|^SHA256_AMD64=.*|SHA256_AMD64=\"${AMD64_HASH}\"|" "${BUILD_DIR}/install.sh"
  sed -i '' "s|^SHA256_ARM64=.*|SHA256_ARM64=\"${ARM64_HASH}\"|" "${BUILD_DIR}/install.sh"
else
  sed -i "s|^VERSION=.*|VERSION=\"${VERSION}\"|" "${BUILD_DIR}/install.sh"
  sed -i "s|^SHA256_AMD64=.*|SHA256_AMD64=\"${AMD64_HASH}\"|" "${BUILD_DIR}/install.sh"
  sed -i "s|^SHA256_ARM64=.*|SHA256_ARM64=\"${ARM64_HASH}\"|" "${BUILD_DIR}/install.sh"
fi
echo "    install.sh generated (VERSION=${VERSION}, SHA256 auto-filled)"

# Print summary
echo ""
echo "==> Build complete! Release files in ${BUILD_DIR}/:"
ls -lh "${BUILD_DIR}"/node_exporter_*.tar.gz "${BUILD_DIR}/install.sh"
