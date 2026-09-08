#!/usr/bin/env bash
set -euo pipefail

# Reproducible third-party asset import.
# We pin the mirror commit so future upstream changes cannot silently alter
# the bytes shipped by the game. Original authorship/license stays Quaternius CC0.
MIRROR_COMMIT="71bbfbdfacd118196994b26da68eec1876d55c6b"
MIRROR_ROOT="https://raw.githubusercontent.com/ilrein/warptracker/${MIRROR_COMMIT}/public/models"
OUT_DIR="assets/third_party/quaternius"

mkdir -p "${OUT_DIR}"

fetch_asset() {
  local remote_name="$1"
  local local_name="$2"
  local destination="${OUT_DIR}/${local_name}"

  echo "Downloading ${remote_name} -> ${destination}"
  curl --fail --location --retry 3 --retry-delay 2 \
    "${MIRROR_ROOT}/${remote_name}" \
    --output "${destination}"

  local size
  size=$(wc -c < "${destination}")
  if [ "${size}" -lt 10000 ]; then
    echo "Asset ${local_name} is unexpectedly small (${size} bytes)." >&2
    exit 1
  fi
}

fetch_asset "knight.glb" "pilgrim_guardian.glb"
fetch_asset "ghost.glb" "wasteland_specter.glb"
fetch_asset "skeleton.glb" "skeleton_raider.glb"
fetch_asset "demon.glb" "ruins_demon.glb"

(
  cd "${OUT_DIR}"
  sha256sum \
    pilgrim_guardian.glb \
    wasteland_specter.glb \
    skeleton_raider.glb \
    ruins_demon.glb \
    > SHA256SUMS.txt
)

echo "CC0 art import complete."
