#!/bin/sh

# --- ASCII ART BASE PATH ---
# This script assumes a directory named 'ascii-art' exists in the same location,
# containing 'base.txt' and 'flatpak.txt'.
ASCII_ART_BASE_PATH="ascii-art"

# --- COLOR DEFINITIONS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m' # New color for ASCII art
BOLD='\033[1m'
NC='\033[0m' # No Color

# Clear the terminal screen for a better visual effect
clear

# Print the ASCII art title from external files
# Note: The script will fail if the files/directory are not found.
if [ -d "$ASCII_ART_BASE_PATH" ]; then
    echo -e "${MAGENTA}"
    cat "${ASCII_ART_BASE_PATH}/base.txt"
    cat "${ASCII_ART_BASE_PATH}/flatpak.txt"
    echo -e "${NC}"
else
    echo -e "${RED}Warning: ASCII art directory not found at '${ASCII_ART_BASE_PATH}'.${NC}"
fi


# --- SETUP FLATHUB REMOTE ---
echo -e "${CYAN}--- Ensuring Flathub remote is configured for the user ---${NC}"
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
echo -e "${GREEN}--- Flathub configuration checked ---${NC}"
echo ""


# --- APPLICATION LISTS ---

# List of applications to install for the current user.
APPS_TO_INSTALL="
org.mozilla.firefox
it.mijorus.gearlever
com.mattjakeman.ExtensionManager
com.github.tchx84.Flatseal
com.brave.Browser
org.videolan.VLC
org.onlyoffice.desktopeditors
io.github.flattool.Warehouse
com.usebottles.bottles
me.iepure.devtoolbox
org.gnome.Boxes
org.gnome.Builder
"

# List of applications to install system-wide.
APPS_TO_INSTALL_SYSTEM="
"

# List of applications to remove from user or system.
APPS_TO_REMOVE="
org.gnome.Calendar
org.gnome.Contacts
org.gnome.Maps
org.gnome.Extensions
"


# --- USER INSTALLATION LOGIC ---
echo -e "${CYAN}--- Starting user installation check ---${NC}"
apps_to_be_installed=""

# First, build a list of apps that are actually missing
for app in $APPS_TO_INSTALL; do
    if ! flatpak info --user "$app" >/dev/null 2>&1; then
        apps_to_be_installed="$apps_to_be_installed $app"
    fi
done

# Now, check if there's anything to install and ask for confirmation
if [ -n "$apps_to_be_installed" ]; then
    echo -e "${BOLD}The following applications will be INSTALLED for the current user:${NC}"
    for app in $apps_to_be_installed; do
        echo -e "  - ${GREEN}$app${NC}"
    done
    echo ""

    printf "${YELLOW}Do you want to proceed with the user installation? (Y/n) ${NC}"
    read -r confirm_install
    echo ""

    case "$confirm_install" in
        [nN]) # Check only for a negative answer
            echo -e "${RED}User installation skipped.${NC}"
            ;;
        *)    # Anything else (including Enter) is treated as "yes"
            echo -e "${GREEN}Proceeding with user installation...${NC}"
            for app in $apps_to_be_installed; do
                echo -e "Installing ${GREEN}$app${NC} from Flathub..."
                flatpak install --user -y flathub "$app"
            done
            ;;
    esac
else
    echo -e "${GREEN}All required user applications are already installed.${NC}"
fi

echo -e "${CYAN}--- Finished user installation check ---${NC}"
echo ""


# --- SYSTEM INSTALLATION LOGIC ---
echo -e "${CYAN}--- Starting system installation check ---${NC}"
system_apps_to_be_installed=""

# First, build a list of system apps that are actually missing
for app in $APPS_TO_INSTALL_SYSTEM; do
    if ! flatpak info --system "$app" >/dev/null 2>&1; then
        system_apps_to_be_installed="$system_apps_to_be_installed $app"
    fi
done

# Now, check if there's anything to install and ask for confirmation
if [ -n "$system_apps_to_be_installed" ]; then
    echo -e "${BOLD}The following applications will be INSTALLED SYSTEM-WIDE:${NC}"
    for app in $system_apps_to_be_installed; do
        echo -e "  - ${GREEN}$app${NC}"
    done
    echo ""
    echo -e "${YELLOW}Note: This requires administrator privileges.${NC}"

    printf "${YELLOW}Do you want to proceed with the system installation? (Y/n) ${NC}"
    read -r confirm_system_install
    echo ""

    case "$confirm_system_install" in
        [nN])
            echo -e "${RED}System installation skipped by user.${NC}"
            ;;
        *)
            echo -e "${GREEN}Proceeding with system installation...${NC}"
            for app in $system_apps_to_be_installed; do
                echo -e "Installing ${GREEN}$app${NC} system-wide from Flathub..."
                sudo flatpak install --system -y flathub "$app"
            done
            ;;
    esac
else
    echo -e "${GREEN}All required system applications are already installed.${NC}"
fi

echo -e "${CYAN}--- Finished system installation check ---${NC}"
echo ""


# --- REMOVAL LOGIC ---
echo -e "${CYAN}--- Starting removal check (user and system) ---${NC}"
apps_to_be_removed=""

# First, build a list of apps that are actually present
for app in $APPS_TO_REMOVE; do
    if flatpak info --user "$app" >/dev/null 2>&1 || flatpak info --system "$app" >/dev/null 2>&1; then
        apps_to_be_removed="$apps_to_be_removed $app"
    fi
done

# Now, check if there's anything to remove and ask for confirmation
if [ -n "$apps_to_be_removed" ]; then
    echo -e "${BOLD}The following applications will be REMOVED:${NC}"
    for app in $apps_to_be_removed; do
        echo -e "  - ${RED}$app${NC}"
    done
    echo ""

    printf "${YELLOW}Do you want to proceed with the removal? (y/N) ${NC}"
    read -r confirm_removal
    echo ""

    case "$confirm_removal" in
        [yY]) # Check only for a positive answer
            echo -e "${RED}Proceeding with removal...${NC}"
            for app in $apps_to_be_removed; do
                if flatpak info --user "$app" >/dev/null 2>&1; then
                    echo -e "Removing ${RED}$app${NC} from user installation..."
                    flatpak uninstall --user -y "$app"
                fi
                if flatpak info --system "$app" >/dev/null 2>&1; then
                    echo -e "Found ${RED}$app${NC} in system installation. Removing with administrator privileges..."
                    sudo flatpak uninstall --system -y "$app"
                fi
            done
            ;;
        *)    # Anything else (including Enter) is treated as "no"
            echo -e "${RED}Removal skipped by user.${NC}"
            ;;
    esac
else
    echo -e "${GREEN}No applications from the removal list were found.${NC}"
fi

echo -e "${CYAN}--- Finished removal check ---${NC}"
echo -e "${BOLD}Operations complete.${NC}"

