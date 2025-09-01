#!/bin/sh

# ==============================================================================
# --- RPM-OSTREE LAYERED PACKAGE INSTALLER SCRIPT ---
#
# This script automates the installation of "layered" packages on immutable
# operating systems like Fedora Silverblue/Kinoite.
#
# Workflow:
# 1. Checks which packages are already installed.
# 2. Asks for confirmation to install the missing packages.
# 3. Installs the requested packages in a single transaction.
# 4. Reminds the user that a reboot is required to apply the changes.
# ==============================================================================

# Source the base utility functions for output formatting
source core/art_base.sh rpm-ostree
source core/printing_suite.sh


# --- REPOSITORY SETUP (SPECIFIC CASES) ---
print_header "Configuring External Repositories"

# Microsoft Visual Studio Code Repository
VSCODE_REPO_FILE="/etc/yum.repos.d/vscode.repo"
if [ ! -f "$VSCODE_REPO_FILE" ]; then
    print_line "Creating Microsoft VS Code repository file (requires root privileges)..."
    # The 'rpm --import' command is NOT needed for rpm-ostree.
    # The gpgkey URL within the .repo file is sufficient.
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    print_line "VS Code repository added successfully." "$GREEN"
else
    print_line "Microsoft VS Code repository is already configured." "$GREEN"
fi
echo ""


# --- PACKAGE LISTS ---

# List of packages to install using rpm-ostree.
# NOTE: The package name for VS Code is 'code'.
PACKAGES_TO_INSTALL="
openssl
code
zsh
"


# --- INSTALLATION LOGIC ---
print_header "Starting Layered Package Installation Check"
packages_to_be_installed=""

# Check the current status to see which packages are already layered
current_layered_packages=$(rpm-ostree status | grep '^\s\sLayeredPackages' | sed 's/Layer-dPackages\s*:\s*//')

for pkg in $PACKAGES_TO_INSTALL; do
    # Check if the package is already in the list of installed ones
    if ! echo "$current_layered_packages" | grep -qw "$pkg"; then
        packages_to_be_installed="$packages_to_be_installed $pkg"
    fi
done

if [ -n "$packages_to_be_installed" ]; then
    print_line "The following packages will be INSTALLED as layered packages:" "$BOLD"
    for pkg in $packages_to_be_installed; do
        print_line "  - $pkg" "$GREEN"
    done
    echo ""
    print_line "WARNING: Installing packages with rpm-ostree modifies the base system image" "$YELLOW"
    print_line "         and will require a REBOOT to apply the changes." "$YELLOW"
    echo ""

    print_prompt "Do you want to proceed with the installation? (Y/n) "
    read -r confirm_install
    echo ""

    case "$confirm_install" in
        [nN])
            print_line "Installation canceled by the user." "$RED"
            ;;
        *)
            print_line "Proceeding with installation (requires administrator privileges)..." "$GREEN"
            # Install all packages in a single transaction for efficiency
            if ! sudo rpm-ostree install $packages_to_be_installed; then
                print_line "Error during rpm-ostree installation. Check the output above." "$RED"
            else
                print_line "Installation completed successfully!" "$GREEN"
                print_line "Please reboot your system to use the new packages." "$BOLD_YELLOW"
            fi
            ;;
    esac
else
    print_line "All required layered packages are already installed." "$GREEN"
fi

print_header "Operations complete"