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

# Source the necessary script files
source core/art_base.sh flatpak
source core/printing_suite.sh


# --- SETUP FLATHUB REMOTE ---
print_header "Ensuring Flathub remote is configured for the user"
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

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
print_header "Starting user installation check"
apps_to_be_installed=""

for app in $APPS_TO_INSTALL; do
    if ! flatpak info --user "$app" >/dev/null 2>&1; then
        apps_to_be_installed="$apps_to_be_installed $app"
    fi
done

if [ -n "$apps_to_be_installed" ]; then
    print_line "The following applications will be INSTALLED for the current user:" "$BOLD"
    for app in $apps_to_be_installed; do
        print_line "  - $app" "$GREEN"
    done
    echo ""

    print_prompt "Do you want to proceed with the user installation? (Y/n) "
    read -r confirm_install
    echo ""

    case "$confirm_install" in
        [nN])
            print_line "User installation skipped." "$RED"
            ;;
        *)
            print_line "Proceeding with user installation..." "$GREEN"
            for app in $apps_to_be_installed; do
                print_line "Installing $app from Flathub..."
                flatpak install --user -y flathub "$app"
            done
            ;;
    esac
else
    print_line "All required user applications are already installed." "$GREEN"
fi


# --- SYSTEM INSTALLATION LOGIC ---
print_header "Starting system installation check"
system_apps_to_be_installed=""

for app in $APPS_TO_INSTALL_SYSTEM; do
    if ! flatpak info --system "$app" >/dev/null 2>&1; then
        system_apps_to_be_installed="$system_apps_to_be_installed $app"
    fi
done

if [ -n "$system_apps_to_be_installed" ]; then
    print_line "The following applications will be INSTALLED SYSTEM-WIDE:" "$BOLD"
    for app in $system_apps_to_be_installed; do
        print_line "  - $app" "$GREEN"
    done
    echo ""
    print_line "Note: This requires administrator privileges." "$YELLOW"

    print_prompt "Do you want to proceed with the system installation? (Y/n) "
    read -r confirm_system_install
    echo ""

    case "$confirm_system_install" in
        [nN])
            print_line "System installation skipped by user." "$RED"
            ;;
        *)
            print_line "Proceeding with system installation..." "$GREEN"
            for app in $system_apps_to_be_installed; do
                print_line "Installing $app system-wide from Flathub..."
                sudo flatpak install --system -y flathub "$app"
            done
            ;;
    esac
else
    print_line "All required system applications are already installed." "$GREEN"
fi


# --- REMOVAL LOGIC ---
print_header "Starting removal check (user and system)"
apps_to_be_removed=""

for app in $APPS_TO_REMOVE; do
    if flatpak info --user "$app" >/dev/null 2>&1 || flatpak info --system "$app" >/dev/null 2>&1; then
        apps_to_be_removed="$apps_to_be_removed $app"
    fi
done

if [ -n "$apps_to_be_removed" ]; then
    print_line "The following applications will be REMOVED:" "$BOLD"
    for app in $apps_to_be_removed; do
        print_line "  - $app" "$RED"
    done
    echo ""

    print_prompt "Do you want to proceed with the removal? (y/N) "
    read -r confirm_removal
    echo ""

    case "$confirm_removal" in
        [yY])
            print_line "Proceeding with removal..." "$RED"
            for app in $apps_to_be_removed; do
                if flatpak info --user "$app" >/dev/null 2>&1; then
                    print_line "Removing $app from user installation..."
                    flatpak uninstall --user -y "$app"
                fi
                if flatpak info --system "$app" >/dev/null 2>&1; then
                    print_line "Found $app in system installation. Removing with administrator privileges..."
                    sudo flatpak uninstall --system -y "$app"
                fi
            done
            ;;
        *)
            print_line "Removal skipped by user." "$RED"
            ;;
    esac
else
    print_line "No applications from the removal list were found." "$GREEN"
fi

print_header "Operations complete"