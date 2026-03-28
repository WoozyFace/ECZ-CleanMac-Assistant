#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APPS_DIR="$DIST_DIR/apps"
DMGS_DIR="$DIST_DIR/dmg"
BUILD_ROOT="${BUILD_ROOT:-/tmp/cleanmacassistent-package-build}"
ASSET_BUILD_DIR="$DIST_DIR/compiled-assets"
TEMP_HOME="${TEMP_HOME:-/tmp/cleanmacassistent-build-home}"
DEVELOPER_DIR_PATH="${DEVELOPER_DIR_PATH:-/Applications/Xcode.app/Contents/Developer}"
ASSET_CATALOG_SOURCE="$ROOT_DIR/XcodeSupport/Assets.xcassets"

VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

function log() {
  printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$1"
}

function require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required tool: $1" >&2
    exit 1
  }
}

function prepare_assets() {
  rm -rf "$ASSET_BUILD_DIR"
  mkdir -p "$ASSET_BUILD_DIR"

  if [[ ! -d "$ASSET_CATALOG_SOURCE" ]]; then
    return
  fi

  /usr/bin/xcrun actool \
    --compile "$ASSET_BUILD_DIR" \
    --platform macosx \
    --minimum-deployment-target 13.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$ASSET_BUILD_DIR/PartialInfo.plist" \
    "$ASSET_CATALOG_SOURCE" >/dev/null
}

function swift_env() {
  env DEVELOPER_DIR="$DEVELOPER_DIR_PATH" HOME="$TEMP_HOME" "$@"
}

function sign_app() {
  local app_path="$1"

  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    /usr/bin/codesign --force --deep --sign - "$app_path"
  else
    /usr/bin/codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$app_path"
  fi
}

function maybe_notarize() {
  local artifact_path="$1"

  if [[ "$SIGN_IDENTITY" == "-" || -z "$NOTARY_PROFILE" ]]; then
    return
  fi

  log "Submitting $(basename "$artifact_path") for notarization"
  /usr/bin/xcrun notarytool submit "$artifact_path" --keychain-profile "$NOTARY_PROFILE" --wait
  /usr/bin/xcrun stapler staple "$artifact_path"
}

function park_existing_path() {
  local target_path="$1"

  if [[ -e "$target_path" ]]; then
    mv "$target_path" "${target_path}.previous-$$" 2>/dev/null || true
  fi
}

function write_info_plist() {
  local plist_path="$1"
  local app_name="$2"
  local bundle_id="$3"
  local bundle_executable="$4"

  cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>$app_name</string>
    <key>CFBundleExecutable</key>
    <string>$bundle_executable</string>
    <key>CFBundleIdentifier</key>
    <string>$bundle_id</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$app_name</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
}

function write_readme() {
  local output_path="$1"
  local app_name="$2"
  local build_kind="$3"

  cat > "$output_path" <<EOF
$app_name
Version $VERSION

Install:
1. Drag $app_name.app to the Applications folder shortcut.
2. Open the app from /Applications.

Notes:
- Build type: $build_kind
- Website: https://cleanmac-assistant.easycompzeeland.nl
- Support: https://easycompzeeland.nl/en/services/hulp-op-afstand

Important:
- The developer build includes internal preview tools and should not be distributed publicly.
- For public website distribution, use a Developer ID signature and notarization.
EOF
}

function build_variant() {
  local configuration="$1"
  local app_name="$2"
  local bundle_id="$3"
  local build_kind="$4"
  local volume_name="$5"

  local bundle_executable="CleanMacAssistantNative"
  local scratch_path="$BUILD_ROOT/$configuration"
  local bin_dir
  local executable_path
  local resources_bundle_path
  local app_path="$APPS_DIR/$app_name.app"
  local staging_slug="${app_name// /-}"
  local app_stage_root="/tmp/cleanmacassistent-app-stage/$staging_slug"
  local app_stage_path="$app_stage_root/$app_name.app"
  local dmg_staging_path="/tmp/cleanmacassistent-dmg-stage/$staging_slug"
  local dmg_temp_path="/tmp/$staging_slug.dmg"
  local dmg_path="$DMGS_DIR/$app_name.dmg"
  local resources_bundle_name="CleanMacAssistantNative_CleanMacAssistantNative.bundle"

  log "Building $app_name ($configuration)"
  swift_env swift build --disable-sandbox -c "$configuration" --scratch-path "$scratch_path"
  bin_dir="$(swift_env swift build --disable-sandbox -c "$configuration" --show-bin-path --scratch-path "$scratch_path")"

  executable_path="$bin_dir/$bundle_executable"
  resources_bundle_path="$bin_dir/$resources_bundle_name"

  if [[ ! -f "$executable_path" ]]; then
    echo "Expected executable not found: $executable_path" >&2
    exit 1
  fi

  rm -rf "$app_stage_root"
  mkdir -p "$app_stage_path/Contents/MacOS" "$app_stage_path/Contents/Resources"

  cp "$executable_path" "$app_stage_path/Contents/MacOS/$bundle_executable"
  if [[ -d "$resources_bundle_path" ]]; then
    cp -R "$resources_bundle_path" "$app_stage_path/Contents/Resources/"
  fi

  if [[ -f "$ASSET_BUILD_DIR/AppIcon.icns" ]]; then
    cp "$ASSET_BUILD_DIR/AppIcon.icns" "$app_stage_path/Contents/Resources/AppIcon.icns"
  fi
  if [[ -f "$ASSET_BUILD_DIR/Assets.car" ]]; then
    cp "$ASSET_BUILD_DIR/Assets.car" "$app_stage_path/Contents/Resources/Assets.car"
  fi

  write_info_plist "$app_stage_path/Contents/Info.plist" "$app_name" "$bundle_id" "$bundle_executable"

  park_existing_path "$app_path"
  rm -rf "$app_path" 2>/dev/null || true
  ditto "$app_stage_path" "$app_path"
  find "$app_path" -name '.smbdelete*' -exec rm -rf {} + 2>/dev/null || true
  sign_app "$app_path"
  maybe_notarize "$app_path"

  rm -rf "$dmg_staging_path" "$dmg_temp_path"
  park_existing_path "$dmg_path"
  rm -rf "$DMGS_DIR/$app_name" 2>/dev/null || true
  mkdir -p "$dmg_staging_path"
  cp -R "$app_path" "$dmg_staging_path/"
  ln -s /Applications "$dmg_staging_path/Applications"
  write_readme "$dmg_staging_path/README.txt" "$app_name" "$build_kind"

  log "Creating DMG for $app_name"
  /usr/bin/hdiutil create -volname "$volume_name" -srcfolder "$dmg_staging_path" -ov -format UDZO "$dmg_temp_path" >/dev/null
  cp "$dmg_temp_path" "$dmg_path"
  maybe_notarize "$dmg_path"
}

require_tool swift
require_tool xcrun
require_tool hdiutil
require_tool codesign
require_tool ditto

mkdir -p "$APPS_DIR" "$DMGS_DIR" "$BUILD_ROOT" "$TEMP_HOME"
prepare_assets

build_variant "release" "CleanMac Assistant" "nl.easycompzeeland.cleanmac-assistant" "Release" "CleanMac Assistant"
build_variant "debug" "CleanMac Assistant Dev" "nl.easycompzeeland.cleanmac-assistant.dev" "Developer" "CleanMac Assistant Dev"

log "Done"
echo "Apps: $APPS_DIR"
echo "DMGs: $DMGS_DIR"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  echo "Note: builds were ad-hoc signed for local use. For public downloads, rerun with SIGN_IDENTITY and NOTARY_PROFILE."
fi
