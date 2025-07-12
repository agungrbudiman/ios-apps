#!/bin/bash

devices=("401E")

# Get the directory of this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data_path="$script_dir/../data.json"
work_path="$script_dir/../ipasign"

if [[ -z "$GITHUB_ACTIONS" ]]; then
    source .secrets
fi

# Prepare workdir
for device in "${devices[@]}"; do
    mkdir -p "$work_path/certs/$device"
    p12="P12_BASE64_$device"
    prov="MOBILEPROVISION_BASE64_$device"
    echo "${!p12}" | base64 -d > $work_path/certs/$device/cert.p12
    echo "${!prov}" | base64 -d > $work_path/certs/$device/prov.mobileprovision
done
mkdir -p "$work_path/signed"
mkdir -p "$work_path/unsigned"

# Read JSON array length
apps_count=$(jq length "$data_path")

# Loop over each app index
for (( i=0; i<apps_count; i++ )); do
    app_id=$(jq -r ".[$i].app_id" "$data_path")
    ipa_url=$(jq -r ".[$i].ipa_url" "$data_path")

    # Download ipa file
    if [[ "$ipa_url" != "null" ]]; then
        if [[ ! -f "$work_path/unsigned/$app_id.ipa" ]]; then
            curl -L -o "$work_path/unsigned/$app_id.ipa" "$ipa_url"
        fi
    fi
done


for ipa in $work_path/unsigned/*.ipa; do
    for cert in $work_path/certs/*; do
        zsign -k $cert/cert.p12 \
            -m $cert/prov.mobileprovision \
            -b $(basename "$ipa" .ipa) \
            -o $work_path/signed/$(basename $cert)_$(basename "$ipa") \
            -p "$P12_PASSWORD" \
            -z 6 \
            $ipa
    done
done