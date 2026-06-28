#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "This file cannot be run directly. It must be sourced by another script."
    exit 1
fi

update_freetube() {
    echo "==> Updating FreeTube..."

    version_file="$HOME/Scripts/Updaters/Versions/freetube.txt"
    TARGET="/Applications/FreeTube.app"

    # Read installed version (tag)
    if [[ -f "$version_file" ]]; then
        installed_version=$(cat "$version_file")
    else
        installed_version=""
    fi

    # Fetch latest *pre-release*
    json=$(gh api repos/FreeTubeApp/FreeTube/releases --jq 'map(select(.prerelease)) | first' 2>/dev/null)
    if [[ $? -ne 0 || -z "$json" ]]; then
        echo "❌ Failed to fetch FreeTube pre-release metadata."
        return 1
    fi

    # Extract tag name (version)
    latest_tag=$(echo "$json" | jq -r '.tag_name // empty')
    if [[ -z "$latest_tag" ]]; then
        echo "❌ No tag_name found in release metadata."
        return 1
    fi

    if [[ "$installed_version" == "$latest_tag" ]]; then
        echo "FreeTube is already up-to-date."
        return
    fi

    echo "Update available..."
    check_processes "FreeTube" "FreeTube Helper" "FreeTube Helper (Renderer)"

    # Select macOS 7z asset
    asset_url=$(echo "$json" | jq -r '.assets[]? | select(.name | test("freetube-.*-mac-x64\\.7z$")) | .browser_download_url // empty')
    digest=$(echo "$json" | jq -r '.assets[]? | select(.name | test("freetube-.*-mac-x64\\.7z$")) | .digest // empty')

    if [[ -z "$asset_url" ]]; then
        echo "❌ No macOS x64 .7z asset found in FreeTube pre-release."
        return 1
    fi

    if [[ "$digest" != sha256:* ]]; then
        echo "❌ No valid SHA256 digest found for FreeTube .7z."
        return 1
    fi

    digest_value="${digest#sha256:}"
    archive_path="$TEMP_DIR/FreeTube.7z"

    echo "Downloading FreeTube .7z..."
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

    echo "Extracting FreeTube.app using 7zz..."
    extract_dir="$TEMP_DIR/extracted"
    mkdir -p "$extract_dir"

    if ! 7zz x "$archive_path" -o"$extract_dir" >/dev/null; then
        echo "❌ Failed to extract .7z with 7zz."
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    # Locate the .app bundle
    app_path=$(find "$extract_dir" -maxdepth 5 -type d -name "FreeTube.app" | head -n 1)

    if [[ -z "$app_path" ]]; then
        echo "❌ FreeTube.app not found inside extracted archive."
        rm -rf "$TEMP_DIR"/*
        return 1
    fi

    echo "Installing FreeTube.app..."
    if [[ -d "$TARGET" ]]; then
        check_processes "FreeTube"
        rm -rf "$TARGET"
    fi

    cp -R "$app_path" "$TARGET"

    echo "Removing quarantine flag..."
    xattr -dr com.apple.quarantine "$TARGET"

    echo "Writing version file..."
    echo "$latest_tag" > "$version_file"

    echo "✅ FreeTube updated successfully."
    
    rm -rf "$TEMP_DIR"/*
}
