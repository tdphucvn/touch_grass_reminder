#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="WorkPulse"
BUNDLE_ID="${BUNDLE_ID:-com.tdphucvn.workpulse}"
INSTALL_MODE="${1:-}"

build_binary() {
  echo "Building release binary..." >&2
  swift build -c release --package-path "$ROOT_DIR" >/dev/stderr

  local binary_path
  binary_path="$(find "$ROOT_DIR/.build" -type f -path "*/release/$APP_NAME" | head -n 1)"
  if [[ -z "$binary_path" ]]; then
    echo "Could not find release binary for $APP_NAME." >&2
    exit 1
  fi

  echo "$binary_path"
}

create_bundle() {
  local binary_path="$1"
  local bundle_path="$ROOT_DIR/dist/$APP_NAME.app"
  local contents_path="$bundle_path/Contents"
  local macos_path="$contents_path/MacOS"

  rm -rf "$bundle_path"
  mkdir -p "$macos_path"

  cp "$binary_path" "$macos_path/$APP_NAME"
  chmod +x "$macos_path/$APP_NAME"

  cat > "$contents_path/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

  # Ad-hoc signing is enough for local use.
  codesign --force --deep --sign - "$bundle_path" >/dev/null

  echo "$bundle_path"
}

install_user() {
  local bundle_path="$1"
  mkdir -p "$HOME/Applications"
  rm -rf "$HOME/Applications/$APP_NAME.app"
  cp -R "$bundle_path" "$HOME/Applications/"
  echo "Installed to: $HOME/Applications/$APP_NAME.app"
}

install_system() {
  local bundle_path="$1"
  sudo rm -rf "/Applications/$APP_NAME.app"
  sudo cp -R "$bundle_path" "/Applications/"
  echo "Installed to: /Applications/$APP_NAME.app"
}

main() {
  local binary_path
  binary_path="$(build_binary)"

  local bundle_path
  bundle_path="$(create_bundle "$binary_path")"
  echo "Created app bundle: $bundle_path"

  case "$INSTALL_MODE" in
    --install-user)
      install_user "$bundle_path"
      ;;
    --install-system)
      install_system "$bundle_path"
      ;;
    "")
      ;;
    *)
      echo "Unknown option: $INSTALL_MODE"
      echo "Usage: scripts/make-app.sh [--install-user|--install-system]"
      exit 1
      ;;
  esac
}

main
