#!/bin/bash

# Get the directory of this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data_path="$script_dir/../data.json"
work_path="$script_dir/../ipasign"

if [[ ! -z "$GITHUB_ACTIONS" ]]; then
    echo "$SECRETS_BASE64" > $script_dir/../.secrets
fi

source .secrets

devices_count=$(jq '.devices | length' "$data_path")

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

# Sign only new entries
if [ ! -n "$BUNDLE_ID" ] || [ "$SIGN_ALL" = "false" ]; then
    jq -r '.apps[].app_id' "$data_path" | sort > /tmp/new_ids
    # data.json from the last 2 commit
    git show $(git log -2 --format=%H -- data.json | tail -n1):data.json | jq -r '.apps[].app_id' | sort > /tmp/old_ids
    comm -13 /tmp/old_ids /tmp/new_ids > /tmp/new_only_ids

    if [ ! -s /tmp/new_only_ids ]; then
      echo "No new app_id entries found."
      exit 0
    fi

    jq -R . /tmp/new_only_ids | jq -s . > /tmp/new_only_ids.json

    jq --slurpfile ids /tmp/new_only_ids.json '
      .apps = (.apps | map(select(.app_id as $id | $ids[0] | index($id))))
    ' "$data_path" > /tmp/data_new.json

    data_path="/tmp/data_new.json"
fi

# Read JSON array length
apps_count=$(jq '.apps | length' "$data_path")

# Loop over each app index
for (( i=0; i<apps_count; i++ )); do
    app_id=$(jq -r ".apps.[$i].app_id" "$data_path")
    ipa_url=$(jq -r ".apps.[$i].ipa_url" "$data_path")

    if [ -n "$BUNDLE_ID" ] && [ "$BUNDLE_ID" != "$app_id" ]; then
        continue
    fi

    # Download ipa file
    if [[ -n "$ipa_url" && "$ipa_url" != "null" ]]; then
        if [[ ! -f "$work_path/unsigned/$app_id.ipa" ]]; then
            curl -L -o "$work_path/unsigned/$app_id.ipa" "$ipa_url"
        fi
    fi
done

shopt -s nullglob
for ipa in $work_path/unsigned/*.ipa; do
    bid="$(basename "$ipa" .ipa)"
    if [ -n "$BUNDLE_ID" ] && [ "$BUNDLE_ID" != "$bid" ]; then
        continue
    fi
    for cert in $work_path/certs/*; do
        device_id="$(basename $cert)"
        pw="P12_PASSWORD_$device_id"
        if [ -s "$cert/cert.p12" ] && [ -s "$cert/prov.mobileprovision" ]; then
            zsign -k $cert/cert.p12 \
                -m $cert/prov.mobileprovision \
                -b $bid \
                -o "$work_path/signed/"$device_id"_$bid.ipa" \
                -p "${!pw}" \
                -z 6 \
                $ipa
        fi
    done
done