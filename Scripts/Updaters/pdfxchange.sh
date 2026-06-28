#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "This file cannot be run directly. It must be sourced by another script."
    exit 1
fi

# 🔄 Function to update PDF-XChange
update_pdfxchange() {
    echo "==> Updating PDF-XChange Editor..."

    JSON_URL="https://raw.githubusercontent.com/ScoopInstaller/Extras/refs/heads/master/bucket/pdf-xchange-editor.json"
    TARGET="$HOME/.wine/drive_c/users/$USER/Programs/PDFXChangeEditor"
    TMP_ZIP="$TEMP_DIR/pdfxchange.zip"
    preserved_files=("History.dat" "HistoryThumbs.dat" "Settings.dat")

    json=$(wget -qO- "$JSON_URL")
    version=$(echo "$json" | jq -r '.version')
    url=$(echo "$json" | jq -r '.architecture."64bit".url')
    expected_hash=$(echo "$json" | jq -r '.architecture."64bit".hash')

    installed_version_file="$TARGET/version.txt"
    if [[ -f "$installed_version_file" ]]; then
        installed_version=$(cat "$installed_version_file")
        if [[ "$installed_version" == "$version" ]]; then
            echo "PDF-XChange Editor $version is already installed."
            return
        fi
    fi

    echo "Downloading version $version..."
    check_processes "wine" "wineserver"
    wget -qO "$TMP_ZIP" "$url"

    echo "Verifying SHA256..."
    actual_hash=$(shasum -a 256 "$TMP_ZIP" | awk '{print $1}')
    if [[ "$actual_hash" != "$expected_hash" ]]; then
        echo "❌ Hash mismatch! Aborting."
        return 1
    fi

    echo "Backing up existing settings..."
    mkdir -p "$TEMP_DIR/settings_backup"
    for file in "${preserved_files[@]}"; do
        if [[ -f "$TARGET/$file" ]]; then
            cp "$TARGET/$file" "$TEMP_DIR/settings_backup/$file"
        fi
    done

    echo "Extracting to $TARGET..."
    if [ -e "$TARGET" ]; then
        chmod -R u+rwX "$TARGET"
    fi
    rm -rf "$TARGET"
    mkdir -p "$TARGET"
    unzip -q "$TMP_ZIP" -d "$TARGET"
    chmod -R u+rwX "$TARGET"
    echo "$version" > "$installed_version_file"

    echo "Restoring preserved settings..."
    for file in "${preserved_files[@]}"; do
        if [[ -f "$TEMP_DIR/settings_backup/$file" ]]; then
            mv "$TEMP_DIR/settings_backup/$file" "$TARGET/$file"
        fi
    done

    echo "✅ PDF-XChange Editor updated to $version"
}