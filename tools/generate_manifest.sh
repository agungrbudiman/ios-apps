#!/bin/bash

# Get the directory of this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data_path="$script_dir/../data.json"
manifest_dir="$script_dir/../manifest"

app_url_prefix="https://github.com/agungrbudiman/ios-apps/releases/download/signed"

devices=("401E" "001C")

# Create output directories
for device in "${devices[@]}"; do
  mkdir -p "$manifest_dir/$device"
done

# Read JSON array length
apps_count=$(jq length "$data_path")

# Loop over each app index
for (( i=0; i<apps_count; i++ )); do
  app_name=$(jq -r ".[$i].app_name" "$data_path")
  app_id=$(jq -r ".[$i].app_id" "$data_path")

  for device in "${devices[@]}"; do
    app_url="$app_url_prefix/$device"_"$app_id.ipa"
    
    plist_content="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
    <dict>
        <key>items</key>
        <array>
            <dict>
                <key>assets</key>
                <array>
                    <dict>
                        <key>kind</key>
                        <string>software-package</string>
                        <key>url</key>
                        <string>${app_url}</string>
                    </dict>
                </array>
                <key>metadata</key>
                <dict>
                    <key>bundle-identifier</key>
                    <string>${app_id}</string>
                    <key>bundle-version</key>
                    <string>2.0</string>
                    <key>kind</key>
                    <string>software</string>
                    <key>title</key>
                    <string>${app_name}</string>
                </dict>
            </dict>
        </array>
    </dict>
</plist>"

    output_file="$manifest_dir/$device/${app_id}.plist"
    printf "%s" "$plist_content" > "$output_file"
    echo "Generated: $device/${app_id}.plist"
  done
done
