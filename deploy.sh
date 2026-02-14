#!/bin/bash
# Build and package node_exporter for multiple architectures (linux/amd64, linux/arm64).
# Usage: ./deploy.sh [version]
#   version: optional, defaults to "v1.1"
#
# Output:
#   build/node_exporter_amd64.tar.gz
#   build/node_exporter_arm64.tar.gz
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

# Print summary
echo ""
echo "==> Build complete! Archives in ${BUILD_DIR}/:"
ls -lh "${BUILD_DIR}"/*.tar.gz
echo ""
echo "NOTE: Update the SHA256 values in scripts/install.sh before releasing."
