#!/bin/bash

IPA_FILE="$1"

if [[ ! -f "$IPA_FILE" ]]; then
  echo "Usage: $0 path/to/app.ipa"
  echo "IPA file not found!"
  exit 1
fi

# Find the Info.plist inside Payload/*.app/
PLIST_PATH=$(unzip -Z1 "$IPA_FILE" | grep -m1 '^Payload/.*\.app/Info.plist$')

if [[ -z "$PLIST_PATH" ]]; then
  echo "Info.plist not found inside IPA!"
  exit 1
fi

# Extract Info.plist to temp file
TMP_PLIST=$(mktemp)
unzip -p "$IPA_FILE" "$PLIST_PATH" > "$TMP_PLIST"

if [[ ! -s "$TMP_PLIST" ]]; then
  echo "Failed to extract Info.plist!"
  rm -f "$TMP_PLIST"
  exit 1
fi

# Parse keys
if command -v /usr/libexec/PlistBuddy &> /dev/null; then
  BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$TMP_PLIST")
  BUNDLE_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleName" "$TMP_PLIST")
  APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$TMP_PLIST")
  BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$TMP_PLIST")
else
  BUNDLE_ID=$(plutil -extract CFBundleIdentifier xml1 -o - "$TMP_PLIST" 2>/dev/null | grep -oPm1 "(?<=<string>)[^<]+")
  BUNDLE_NAME=$(plutil -extract CFBundleName xml1 -o - "$TMP_PLIST" 2>/dev/null | grep -oPm1 "(?<=<string>)[^<]+")
  APP_VERSION=$(plutil -extract CFBundleShortVersionString xml1 -o - "$TMP_PLIST" 2>/dev/null | grep -oPm1 "(?<=<string>)[^<]+")
  BUNDLE_VERSION=$(plutil -extract CFBundleVersion xml1 -o - "$TMP_PLIST" 2>/dev/null | grep -oPm1 "(?<=<string>)[^<]+")
fi

echo "Bundle Identifier: $BUNDLE_ID"
echo "Bundle Name: $BUNDLE_NAME"
echo "App Version: $APP_VERSION"
echo "Bundle Version: $BUNDLE_VERSION"

rm -f "$TMP_PLIST"
