#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

APP_PATH="$ROOT_DIR/.derived-data/Build/Products/Debug/SlateCue.app"
ICON_SOURCE="$ROOT_DIR/design/AppIcon-source.png"
ICON_SENTINEL="$ROOT_DIR/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png"

ensure_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 1
  fi
}

should_regenerate_icon() {
  if [[ ! -f "$ICON_SOURCE" ]]; then
    return 1
  fi

  if [[ ! -f "$ICON_SENTINEL" ]]; then
    return 0
  fi

  [[ "$ICON_SOURCE" -nt "$ICON_SENTINEL" ]]
}

ensure_command swift
ensure_command xcodegen
ensure_command xcodebuild
ensure_command open

if should_regenerate_icon; then
  echo "Regenerating app icon assets..."
  "$ROOT_DIR/scripts/build_app_icon.sh"
fi

echo "Generating Xcode project..."
xcodegen generate

echo "Building SlateCue.app..."
xcodebuild \
  -project SlateCue.xcodeproj \
  -scheme SlateCue \
  -configuration Debug \
  -derivedDataPath "$ROOT_DIR/.derived-data" \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app bundle not found at $APP_PATH" >&2
  exit 1
fi

echo "Launching app bundle..."
open -n "$APP_PATH"
