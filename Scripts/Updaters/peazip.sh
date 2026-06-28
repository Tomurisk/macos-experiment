#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "This file cannot be run directly. It must be sourced by another script."
    exit 1
fi

update_peazip() {
    echo "==> Updating PeaZip..."

    version_file="$HOME/Scripts/Updaters/Versions/peazip.txt"
    TARGET="/Applications/peazip.app"

    # Read installed version (tag)
    if [[ -f "$version_file" ]]; then
        installed_version=$(cat "$version_file")
    else
        installed_version=""
    fi

    # Fetch latest release (not prerelease)
    json=$(gh api repos/peazip/PeaZip/releases/latest 2>/dev/null)
    if [[ $? -ne 0 || -z "$json" ]]; then
        echo "❌ Failed to fetch PeaZip release metadata."
        return 1
    fi

    # Extract tag name (version)
    latest_tag=$(echo "$json" | jq -r '.tag_name // empty')
    if [[ -z "$latest_tag" ]]; then
        echo "❌ No tag_name found in release metadata."
        return 1
    fi

    if [[ "$installed_version" == "$latest_tag" ]]; then
        echo "PeaZip is already up-to-date."
        return
    fi

    echo "Update available..."
    check_processes "PeaZip"

    # Select macOS x86_64 ZIP asset
    asset_url=$(echo "$json" | jq -r '.assets[]? | select(.name | test("peazip-.*\\.DARWIN\\.x86_64\\.zip$")) | .browser_download_url // empty')
    digest=$(echo "$json" | jq -r '.assets[]? | select(.name | test("peazip-.*\\.DARWIN\\.x86_64\\.zip$")) | .digest // empty')

    if [[ -z "$asset_url" ]]; then
        echo "❌ No macOS x86_64 ZIP asset found in PeaZip release."
        return 1
    fi

    if [[ "$digest" != sha256:* ]]; then
        echo "❌ No valid SHA256 digest found for PeaZip ZIP."
        return 1
    fi

    digest_value="${digest#sha256:}"
    archive_path="$TEMP_DIR/PeaZip.zip"

    echo "Downloading PeaZip ZIP..."
    if ! wget -O "$archive_path" "$asset_url"; then
        echo "❌ Download failed."
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    echo "Verifying SHA256..."
    if ! echo "$digest_value  $archive_path" | shasum -a 256 -c -; then
        echo "❌ SHA256 mismatch!"
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    echo "Extracting PeaZip.app using 7zz..."
    extract_dir="$TEMP_DIR/extracted"
    mkdir -p "$extract_dir"

    if ! 7zz x "$archive_path" -o"$extract_dir" >/dev/null; then
        echo "❌ Failed to extract ZIP with 7zz."
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    # Locate the .app bundle inside the subfolder
    app_path=$(find "$extract_dir" -maxdepth 5 -type d -iname "peazip.app" | head -n 1)

    if [[ -z "$app_path" ]]; then
        echo "❌ PeaZip.app not found inside extracted archive."
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    echo "Installing PeaZip.app..."
    if [[ -d "$TARGET" ]]; then
        rm -rf "$TARGET"
    fi

    cp -R "$app_path" "$TARGET"

    echo "Removing quarantine flag..."
    xattr -dr com.apple.quarantine "$TARGET"

    echo "Writing version file..."
    echo "$latest_tag" > "$version_file"

    echo "✅ PeaZip updated successfully."

    rm -rf "$TEMP_DIR"/*
}
