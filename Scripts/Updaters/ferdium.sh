#!/bin/bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "This file cannot be run directly. It must be sourced by another script."
    exit 1
fi

update_ferdium() {
    echo "==> Updating Ferdium..."

    version_file="$HOME/Scripts/Updaters/Versions/ferdium.txt"
    TARGET="/Applications/Ferdium.app"

    # Read installed version (date)
    if [[ -f "$version_file" ]]; then
        installed_date=$(cat "$version_file")
    else
        installed_date=""
    fi

    # Fetch latest release metadata
    json=$(gh api repos/Tomurisk/ferdium-custom-build/releases/latest 2>/dev/null)
    if [[ $? -ne 0 || -z "$json" ]]; then
        echo "❌ Failed to fetch release metadata."
        return 1
    fi

    # Extract release publish date
    release_date=$(echo "$json" | jq -r '.published_at // empty')
    if [[ -z "$release_date" ]]; then
        echo "❌ No published_at field found."
        return 1
    fi

    # Convert to YYYY-MM-DD
    release_date_short=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$release_date" "+%Y-%m-%d %H:%M" 2>/dev/null)
    if [[ -z "$release_date_short" ]]; then
        echo "❌ Failed to parse release date: $release_date"
        return 1
    fi

    # Compare with version file
    if [[ "$installed_date" == "$release_date_short" ]]; then
        echo "Ferdium is already up-to-date."
        return
    fi

    echo "Update available..."
    check_processes "Ferdium"

    # Explicitly select Ferdium-x64.dmg
    asset_url=$(echo "$json" | jq -r '.assets[]? | select(.name == "Ferdium-x64.dmg") | .browser_download_url // empty')
    digest=$(echo "$json" | jq -r '.assets[]? | select(.name == "Ferdium-x64.dmg") | .digest // empty')

    if [[ -z "$asset_url" ]]; then
        echo "❌ Ferdium-x64.dmg not found in release assets."
        return 1
    fi

    if [[ "$digest" != sha256:* ]]; then
        echo "❌ No valid SHA256 digest found for Ferdium-x64.dmg."
        return 1
    fi

    digest_value="${digest#sha256:}"
    dmg_path="$TEMP_DIR/Ferdium-x64.dmg"

    echo "Downloading Ferdium-x64.dmg..."
    if ! wget -O "$dmg_path" "$asset_url"; then
        echo "❌ Download failed."
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    echo "Verifying SHA256..."
    if ! echo "$digest_value  $dmg_path" | shasum -a 256 -c -; then
        echo "❌ SHA256 mismatch!"
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    echo "Extracting Ferdium.app using 7zz..."
    extract_dir="$TEMP_DIR/extracted"
    mkdir -p "$extract_dir"

    if ! 7zz x "$dmg_path" -o"$extract_dir" >/dev/null; then
        echo "❌ Failed to extract DMG with 7zz."
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    # Locate the .app bundle
    app_path=$(find "$extract_dir" -maxdepth 4 -type d -name "Ferdium.app" | head -n 1)

    if [[ -z "$app_path" ]]; then
        echo "❌ Ferdium.app not found inside extracted DMG."
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    echo "Installing Ferdium.app..."
    if [[ -d "$TARGET" ]]; then
        check_processes "Ferdium"
        rm -rf "$TARGET"
    fi

    cp -R "$app_path" "$TARGET"

    echo "Removing quarantine flag..."
    xattr -dr com.apple.quarantine "$TARGET"

    echo "Writing version file..."
    echo "$release_date_short" > "$version_file"

    echo "✅ Ferdium updated successfully."

    rm -rf "$TEMP_DIR"/*
}
