#!/bin/bash
# Sync GPU exporter code from upstream nvidia_gpu_exporter repository.
# This script pulls the latest internal/exporter and internal/util code
# from https://github.com/utkuozdemir/nvidia_gpu_exporter and patches
# the import paths for use within this project.
#
# Usage: bash scripts/sync_gpu_exporter.sh [branch|tag]
#   branch/tag: optional, defaults to "master"

set -e

UPSTREAM_REPO="https://github.com/utkuozdemir/nvidia_gpu_exporter.git"
UPSTREAM_MODULE="github.com/utkuozdemir/nvidia_gpu_exporter"
LOCAL_MODULE="github.com/prometheus/node_exporter"
BRANCH="${1:-master}"

# Directories to sync (relative to repo root)
SYNC_DIRS=("internal/exporter" "internal/util")

# Temporary directory for cloning
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "=========================================="
echo "  Sync GPU Exporter from upstream"
echo "=========================================="
echo ""
echo "  Repo:   ${UPSTREAM_REPO}"
echo "  Branch: ${BRANCH}"
echo ""

# Sparse clone (only fetch what we need)
echo "==> Cloning upstream (sparse)..."
git clone --depth 1 --branch "$BRANCH" --filter=blob:none --sparse \
  "$UPSTREAM_REPO" "$TMP_DIR" 2>&1 | tail -1

cd "$TMP_DIR"
git sparse-checkout set "${SYNC_DIRS[@]}"
cd - > /dev/null

echo "==> Syncing files..."
for dir in "${SYNC_DIRS[@]}"; do
  src="$TMP_DIR/$dir"
  dst="./$dir"

  if [ ! -d "$src" ]; then
    echo "    [SKIP] $dir (not found in upstream)"
    continue
  fi

  # Remove old files (except test files we may have locally)
  mkdir -p "$dst"
  # Only sync .go source files (exclude test files to avoid test dependency issues)
  for f in "$src"/*.go; do
    [ -f "$f" ] || continue
    filename=$(basename "$f")

    # Skip test files to avoid pulling in test-only dependencies
    if [[ "$filename" == *"_test.go" ]]; then
      continue
    fi

    cp "$f" "$dst/$filename"
    echo "    [SYNC] $dir/$filename"
  done
done

# Patch import paths
echo ""
echo "==> Patching import paths..."
echo "    ${UPSTREAM_MODULE} -> ${LOCAL_MODULE}"

for dir in "${SYNC_DIRS[@]}"; do
  for f in "./$dir"/*.go; do
    [ -f "$f" ] || continue
    if grep -q "$UPSTREAM_MODULE" "$f" 2>/dev/null; then
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s|${UPSTREAM_MODULE}|${LOCAL_MODULE}|g" "$f"
      else
        sed -i "s|${UPSTREAM_MODULE}|${LOCAL_MODULE}|g" "$f"
      fi
      echo "    [PATCH] $f"
    fi
  done
done

# Show upstream version info
echo ""
echo "==> Upstream version info:"
COMMIT=$(cd "$TMP_DIR" && git log -1 --format='%h %s (%ci)')
echo "    ${COMMIT}"

echo ""
echo "==> Sync complete! Please run:"
echo "    go mod tidy && go build ./..."
echo ""
