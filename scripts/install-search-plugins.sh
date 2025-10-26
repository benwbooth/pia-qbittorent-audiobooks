#!/usr/bin/env bash
# Fetch every official qBittorrent search plugin from the upstream repository
# and drop it into this project's qBittorrent config.

set -euo pipefail

ENGINES_API_URL="https://api.github.com/repos/qBittorrent/search-plugins/contents/nova3/engines"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_TARGET="$REPO_ROOT/qbittorrent/config/qBittorrent/nova3/engines"

usage() {
  cat <<'EOF'
Usage: install-search-plugins.sh [-d DIR]

Options:
  -d DIR   Destination engines directory (defaults to ./qbittorrent/config/qBittorrent/nova3/engines)
  -h       Show this help text.

Downloads every plugin listed in the official qBittorrent/search-plugins repo
and writes them into DIR with executable permissions so the container picks
them up via the bind-mounted config volume.
EOF
}

TARGET_DIR="$DEFAULT_TARGET"
while getopts ":d:h" opt; do
  case "$opt" in
    d) TARGET_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) usage >&2; exit 1 ;;
  esac
done

for bin in curl jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "error: required tool '$bin' not found" >&2
    exit 1
  fi
done

mkdir -p "$TARGET_DIR"

tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT

echo "Fetching plugin list from $ENGINES_API_URL..."
curl -fsSL "$ENGINES_API_URL" -o "$tmp_json"

mapfile -t plugin_urls < <(jq -r '.[] | select(.type=="file") | .download_url' "$tmp_json")
if [[ ${#plugin_urls[@]} -eq 0 ]]; then
  echo "error: no plugins discovered in upstream list" >&2
  exit 1
fi

for url in "${plugin_urls[@]}"; do
  filename="${url##*/}"
  dest="$TARGET_DIR/$filename"
  echo "Installing $filename..."
  curl -fsSL "$url" -o "$dest"
  chmod 755 "$dest"
done

echo "Installed ${#plugin_urls[@]} plugins into $TARGET_DIR"
