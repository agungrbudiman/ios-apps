#!/bin/bash

IPA_FILE="$1"

if [[ ! -f "$IPA_FILE" ]]; then
  echo "Usage: $0 path/to/app.ipa"
  echo "IPA file not found!"
  exit 1
fi

# Locate the Info.plist path
PLIST_PATH=$(unzip -Z1 "$IPA_FILE" | grep -m1 '^Payload/.*\.app/Info.plist$')
if [[ -z "$PLIST_PATH" ]]; then
  echo "Info.plist not found inside IPA!"
  exit 1
fi

# Extract the Info.plist to a temp file
TMP_PLIST=$(mktemp)
unzip -p "$IPA_FILE" "$PLIST_PATH" > "$TMP_PLIST"

# Detect if it's binary (first 8 bytes are 'bplist')
if head -c 8 "$TMP_PLIST" | grep -q "bplist"; then
  echo "Detected binary Info.plist, converting to XML..."

  if command -v plutil &>/dev/null; then
    # macOS conversion
    plutil -convert xml1 "$TMP_PLIST"
  else
    # Python-based conversion for Linux
    python3 - <<EOF
import plistlib, sys
path = "$TMP_PLIST"
with open(path, "rb") as f:
    data = plistlib.load(f)
with open(path, "wb") as f:
    plistlib.dump(data, f)
EOF
  fi
fi

# Extract key from XML plist using sed
parse_plist_key() {
  sed -n "/<key>$1<\/key>/,/<\/string>/s:.*<string>\(.*\)</string>.*:\1:p" "$TMP_PLIST"
}

BUNDLE_ID=$(parse_plist_key CFBundleIdentifier)
BUNDLE_NAME=$(parse_plist_key CFBundleName)
APP_VERSION=$(parse_plist_key CFBundleShortVersionString)
BUNDLE_VERSION=$(parse_plist_key CFBundleVersion)

echo "Bundle Identifier: $BUNDLE_ID"
echo "Bundle Name: $BUNDLE_NAME"
echo "App Version: $APP_VERSION"
echo "Bundle Version: $BUNDLE_VERSION"

rm -f "$TMP_PLIST"
