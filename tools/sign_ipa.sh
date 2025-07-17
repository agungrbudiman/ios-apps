#!/bin/bash

# Get the directory of this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data_path="$script_dir/../data.json"
work_path="$script_dir/../ipasign"

if [ ! -z "$GITHUB_ACTIONS" ]; then
    echo "$SECRETS_BASE64" > $script_dir/../.secrets
fi

source .secrets

devices_count=$(jq '.devices | length' "$data_path")
app_url_prefix=$(jq -r '.base_signed_url' $data_path)

# Prepare workdir
for (( i=0; i<devices_count; i++ )); do
    enabled=$(jq -r ".devices[$i].enabled" "$data_path")
    if [ "$enabled" = "false" ]; then
        continue
    fi
    device_id=$(jq -r ".devices[$i].id" "$data_path")
    mkdir -p "$work_path/certs/$device_id"
    p12="P12_BASE64_$device_id"
    prov="MOBILEPROVISION_BASE64_$device_id"
    echo "${!p12}" | base64 -d > $work_path/certs/$device_id/cert.p12
    echo "${!prov}" | base64 -d > $work_path/certs/$device_id/prov.mobileprovision
done
mkdir -p "$work_path/signed"
mkdir -p "$work_path/unsigned"

# Read JSON array length
apps_count=$(jq '.apps | length' "$data_path")

shopt -s nullglob
# Loop over each app index
for (( i=0; i<apps_count; i++ )); do
    app_id=$(jq -r ".apps.[$i].app_id" "$data_path")
    app_name=$(jq -r ".apps.[$i].app_name" "$data_path")
    ipa_url=$(jq -r ".apps.[$i].ipa_url" "$data_path")
    app_version=$(jq -r ".apps.[$i].app_version" "$data_path")

    # skip non matched bundle_id if specified
    if [ -n "$BUNDLE_ID" ] && [ "$BUNDLE_ID" != "$app_id" ]; then
        continue
    fi

    for cert in $work_path/certs/*; do
        device_id="$(basename $cert)"
        pw="P12_PASSWORD_$device_id"

        # skip signed apps unless bundle_id specified or sign_all is true
        if [[ ! -n "$BUNDLE_ID" && ( ! -n "$SIGN_ALL" || "$SIGN_ALL" = "false" ) ]]; then
            # check uploaded file when run from github action
            if [ ! -z "$GITHUB_ACTIONS" ]; then
                if curl --output /dev/null --silent --head --fail "$app_url_prefix/"$device_id"_"$app_id"_$app_version.ipa"; then
                    echo "$app_name is already signed, skip..."
                    continue
                fi
            # check local file when run from local machine
            else
                if [ -f "$work_path/signed/$device_id"_"$app_id"_"$app_version.ipa" ]; then
                    echo "$app_name is already signed, skip..."
                    continue
                fi
            fi    
        fi

        # Download ipa file
        if [ ! -f "$work_path/unsigned/$app_id"_"$app_version.ipa" ]; then
            curl -L --silent --fail -o "$work_path/unsigned/$app_id"_"$app_version.ipa" "$ipa_url"
            if [ $? -ne 0 ]; then
                echo "$app_name failed to download, skip..."
                continue
            fi
        fi

        if [ -n "${!pw}" ] && [ -s "$cert/cert.p12" ] && [ -s "$cert/prov.mobileprovision" ]; then
            zsign -k $cert/cert.p12 \
                -m $cert/prov.mobileprovision \
                -b "$app_id" \
                -n "$app_name" \
                -o "$work_path/signed/"$device_id"_"$app_id"_""$app_version.ipa" \
                -p "${!pw}" \
                -z 6 \
                "$work_path/unsigned/$app_id"_"$app_version.ipa"
        fi
    done
done