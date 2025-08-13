#!/bin/sh

# ==============================================================================
# --- GNOME SHELL EXTENSION INSTALLER SCRIPT (Self-Re-running Logic) ---
#
# This script automates the installation and activation of GNOME extensions.
#
# Smart Workflow:
# 1. First Run: Installs selected extensions. Then instructs the user to
#    restart the shell and run this same script again.
# 2. Second Run: The script detects that extensions are already installed
#    and proceeds to enable them, which now succeeds.
# ==============================================================================

# --- SOURCE REQUIRED FILES ---
source ./art_base.sh gse
source ./printing_suite.sh


# --- SCRIPT CONFIGURATION ---
EXTENSION_IDS="
3193
19
307
517
615
779
1460
5470
1319
"

# --- SCRIPT START ---
print_header "GNOME Shell Extension Installer"

# --- 1. DEPENDENCY AND VERSION CHECK ---
print_line "Checking for required tools: 'curl', 'jq', and 'unzip'..."

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        print_line "ERROR: Required tool '$1' not found." "${BOLD}${RED}"
        print_line "Please install it using your system's package manager and try again."
        exit 1
    fi
}

check_command "curl"
check_command "jq"
check_command "unzip"
check_command "gnome-shell"

print_line "All required tools found." "$GREEN"

SHELL_VERSION=$(gnome-shell --version | cut -d ' ' -f 3 | cut -d '.' -f 1)
print_line "Detected GNOME Shell version: $SHELL_VERSION" "$BOLD"
echo ""

# --- 2. MAIN PROCESSING LOOP ---
print_header "Processing Extensions"

# Flag to track if we installed anything new in this run
NEW_INSTALL_HAPPENED=false
TMP_DIR=$(mktemp -d)

for id in $EXTENSION_IDS; do
    print_line "--------------------------------------------------" "$CYAN"
    print_line "Processing Extension ID: $id"

    API_URL="https://extensions.gnome.org/extension-info/?pk=$id"
    JSON_DATA=$(curl -sf "$API_URL")

    if [ -z "$JSON_DATA" ]; then
        print_line " -> ERROR: Could not fetch data for ID $id. Skipping." "$RED"
        continue
    fi

    EXT_NAME=$(echo "$JSON_DATA" | jq -r '.name')
    UUID=$(echo "$JSON_DATA" | jq -r '.uuid')

    if [ -z "$UUID" ] || [ "$UUID" = "null" ]; then
        print_line " -> ERROR: Could not parse UUID for ID $id. Skipping." "$RED"
        continue
    fi

    # Check if the extension is already installed
    if gnome-extensions list | grep -q "$UUID"; then
        print_line " -> Extension '$EXT_NAME' is already installed."
        # Check if it's enabled
        if ! gnome-extensions list --enabled | grep -q "$UUID"; then
            print_line " -> Status: Disabled. Attempting to enable..."
            if gnome-extensions enable "$UUID"; then
                print_line " -> Successfully enabled." "$GREEN"
            else
                print_line " -> ERROR: Failed to enable." "$RED"
            fi
        else
            print_line " -> Status: Already enabled." "$GREEN"
        fi
    else
        # --- Installation Logic for new extensions ---
        print_prompt "Do you want to install '$EXT_NAME'? [Y/n] "
        read -r confirm_install

        case "${confirm_install:-y}" in
          [nN]*)
            print_line " -> Skipping '$EXT_NAME' as requested." "$YELLOW"
            continue
            ;;
        esac

        DOWNLOAD_URL="https://extensions.gnome.org/download-extension/${UUID}.shell-extension.zip?shell_version=${SHELL_VERSION}"
        print_line " -> Constructing download URL for shell v$SHELL_VERSION"

        ZIP_FILE="$TMP_DIR/extension_${id}.zip"
        print_line " -> Downloading $ZIP_FILE..."

        if ! curl -fsSL -o "$ZIP_FILE" "$DOWNLOAD_URL"; then
            print_line " -> ERROR: Download failed. The extension may not support GNOME Shell v$SHELL_VERSION." "$RED"
            continue
        fi

        if gnome-extensions install --force "$ZIP_FILE" >/dev/null 2>&1; then
            print_line " -> Installation successful." "$GREEN"
            NEW_INSTALL_HAPPENED=true
        else
            print_line " -> ERROR: Failed to install bundle '$ZIP_FILE'." "$RED"
        fi
    fi
done

# --- 3. CLEANUP AND FINAL INSTRUCTIONS ---
rm -rf "$TMP_DIR"

print_header "Operations Complete"

if [ "$NEW_INSTALL_HAPPENED" = true ]; then
    print_line "New extensions have been installed." "$YELLOW"
    print_line "To complete the activation, please follow these 2 steps:"
    print_line "1. Restart GNOME Shell." "$BOLD"
    print_line "   - On X11: Press Alt+F2, type 'r', and press Enter."
    print_line "   - On Wayland: You must log out and log back in."
    print_line "2. Run this same script again." "$BOLD"
else
    print_line "All extensions have been checked and enabled." "$GREEN"
fi

exit 0
