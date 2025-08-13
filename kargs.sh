#!/bin/sh

# ###################################################################
# Script to apply the i915.enable_dc=0 karg for Intel GPUs
# This prevents random screen freezes on some systems with
# low-power processors (e.g., on Fedora Silverblue/Kinoite).
#
# This version is adapted to use the advanced printing suite.
# ###################################################################

# Source the necessary script files
source ./art_base.sh kargs
source ./printing_suite.sh

# --- SCRIPT START ---
clear
print_header "Patch for Intel GPU Freezes"

# --- EXPLANATION ---
print_line "This script will help you apply a fix to prevent occasional"
print_line "screen freezes on certain computers with Intel low-power processors."
echo "" # Add a manual space for readability
print_line "Technically, it will run the following command:"
print_line "sudo rpm-ostree kargs --append=i915.enable_dc=0" "$BOLD"
echo ""

# --- USER CONFIRMATION ---
print_prompt "Do you want to proceed with applying the patch? [Y/n] "
read -r confirm_apply
echo "" # Add a newline after user input for clean output

# Convert the answer to lowercase; default is 'y' if the user just presses Enter
case "${confirm_apply:-y}" in
  [yY]*)
    print_line "Applying the patch..." "$GREEN"

    # Apply the kernel argument.
    # NOTE: Corrected the command to use '--append=' (with an equals sign).
    if sudo rpm-ostree kargs --append=i915.enable_dc=0; then
      print_line "Patch applied successfully!" "$GREEN"
      print_line "To make the change effective, you must reboot the system."
      echo ""

      # Ask if the user wants to reboot now
      print_prompt "Do you want to reboot the system now? [Y/n] "
      read -r confirm_reboot
      echo ""

      case "${confirm_reboot:-y}" in
        [yY]*)
          print_line "Rebooting the system..." "$GREEN"
          # Perform the reboot using 'sudo systemctl reboot' which is the standard.
          sudo systemctl reboot
          ;;
        *)
          print_line "Operation completed. Please remember to reboot your system manually."
          exit 0
          ;;
      esac
    else
      # This block runs if the rpm-ostree command fails
      print_line "ERROR: The patch was not applied." "${BOLD}${RED}"
      print_line "An error occurred while running rpm-ostree."
      print_line "Please ensure you entered the sudo password correctly and are on an ostree-based system."
      exit 1
    fi
    ;;
  *)
    print_line "Operation cancelled by the user." "$YELLOW"
    print_line "No changes have been made to the system."
    exit 0
    ;;
esac