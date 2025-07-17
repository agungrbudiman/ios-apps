#!/bin/bash

# Get the directory of this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data_path="${script_dir}/../data.json"
manifest_dir="${script_dir}/../manifest"

app_url_prefix=$(jq -r '.base_signed_url' "$data_path")

devices_count=$(jq '.devices | length' "$data_path")

# Create output directories
rm -rf $manifest_dir
for (( i=0; i<devices_count; i++ )); do
    device_id=$(jq -r ".devices[$i].id" "$data_path")
    enabled=$(jq -r ".devices[$i].enabled" "$data_path")
    [ "$enabled" = "true" ] && mkdir -p "${manifest_dir}/${device_id}"
done

apps_count=$(jq '.apps | length' "$data_path")

# Loop over each app index
for (( i=0; i<apps_count; i++ )); do
  app_name=$(jq -r ".apps[$i].app_name" "$data_path")
  app_id=$(jq -r ".apps[$i].app_id" "$data_path")
  app_version=$(jq -r ".apps[$i].app_version" "$data_path")

  for (( y=0; y<devices_count; y++ )); do
    device_id=$(jq -r ".devices[$y].id" "$data_path")
    enabled=$(jq -r ".devices[$y].enabled" "$data_path")
    [ "$enabled" = "false" ] && continue
    app_url="${app_url_prefix}/${device_id}_${app_id}_${app_version}.ipa"
    
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

    output_file="${manifest_dir}/${device_id}/${app_id}.plist"
    printf "%s" "$plist_content" > "$output_file"
    echo "Generated: ${device_id}/${app_id}.plist"
  done
done
