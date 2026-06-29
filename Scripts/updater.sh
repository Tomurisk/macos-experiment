#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Harden wget (Homebrew wget supports full TLS enforcement)
alias wget='wget --https-only --secure-protocol=TLSv1_2 --max-redirect=5 --no-iri'

INSTALL_DIR="/Applications"
TEMP_DIR="$(mktemp -d)"

# Network check (macOS ping uses -t instead of -W)
if ! ping -q -c 1 -t 2 google.com >/dev/null 2>&1; then
    read -p "💥 No internet connection. Check your network and try again."
    exit 1
fi

# Required commands for macOS
required_cmds=(curl jq tar grep gh wget)

for cmd in "${required_cmds[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        read -p "$cmd is required but not installed. Exiting."
        exit 1
    fi
done

check_processes() {
    local processes=("$@")

    while true; do
        local running=false
        declare -A seen_execs=()

        for proc in "${processes[@]}"; do
            # macOS-safe process search: match only executable name, not full command line
            mapfile -t pids < <(pgrep -x "$proc")

            if (( ${#pids[@]} > 0 )); then
                running=true
                for pid in "${pids[@]}"; do
                    exec_name=$(ps -p "$pid" -o comm=)
                    seen_execs["$exec_name"]=1
                done
            fi
        done

        if $running; then
            echo "The following executables are still running:"
            for exec in "${!seen_execs[@]}"; do
                echo " - $exec"
            done

            read -n 1 -s -p "Close them. Press 'n' to quit or any other key to continue..." key
            echo

            if [[ $key == 'n' ]]; then
                echo "Exiting the script."
                exit 0
            fi
        else
            echo "All specified executables are closed."
            break
        fi

        sleep 1
    done
}

source "$SCRIPT_DIR/Updaters/ferdium.sh"
source "$SCRIPT_DIR/Updaters/freetube.sh"
source "$SCRIPT_DIR/Updaters/peazip.sh"
source "$SCRIPT_DIR/Updaters/winebundle.sh"
source "$SCRIPT_DIR/Updaters/pdfxchange.sh"

# 🔁 Run all updates
update_ferdium
update_freetube
update_peazip
update_wine_bundle
update_pdfxchange

# 🧹 Cleanup
rm -rf "$TEMP_DIR"
echo "🎉 All applications are up-to-date!"

osascript -e 'tell application "Terminal" to close front window'